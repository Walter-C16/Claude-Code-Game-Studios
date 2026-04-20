# Quick Design Spec: Companion Leveling

> **Type**: Combat progression system — the "grindable" power axis
> **Author**: game-designer
> **Created**: 2026-04-15
> **Cross refs**: design/quick-specs/companion-battle-stats.md (base stats level scales on top of), design/gdd/companion-data.md (parent system), design/gdd/exploration.md (Rule 7 — existing XP source)

---

## Problem

Dark Olympus has **two progression axes** for companions:

1. **Romance stage (0–4)** — earned by gifts / conversations. Unlocks blessings + intimacy.
2. **Level (???)** — earned by XP from combat / exploration. Scales base stats.

> **Historical note (2026-04):** A third axis (Epithets I–VI) was designed to live on top of the Oracle gacha. Both the Oracle/Forge gacha systems and the Epithet tier have been removed. Level is now the only mechanical power-axis; romance stays the narrative one.

Axis 1 is designed and implemented. Axis 2 had only scaffolding: `GameStore._companion_xp` is a Dictionary that accepts `add_companion_xp(id, amount)` calls from the exploration system, but no calculation logic, no stat scaling, no UI, no level thresholds. Players grind XP with nothing to show for it.

Leveling should be the "play the game more, get stronger" feedback loop that sits orthogonal to romance (narrative progression).

## Solution

Add a **manual level-up system** that uses the existing `_companion_xp` pool as a resource bank, a new `_companion_levels` storage, and a player-driven "Level Up" button. Leveling up requires BOTH enough banked XP AND enough gold — it is NOT automatic. Gold is the primary long-term sink; XP is earned and spent like a second currency. Stat bonuses apply in `BattleManager.setup()` between base stats and blessing layering. Cap 20, quadratic XP curve, small-per-level + milestone bonuses, protagonist scales the same way.

Lore framing: the goddesses are fallen and recovering — every fight and mission reignites a fraction of their divine power. Leveling isn't "training"; it's "remembering who they were".

## Formulas

### XP needed to reach a level

```
xp_total(level) = 25 * level * (level - 1)    # level ∈ [1, 20]
```

Derivation: start from `xp_needed_for_next(n) = 50 * n`, sum from 1 to L-1. Total is `25 * L * (L - 1)`.

| Level | XP delta (from prev) | XP total |
|---|---|---|
| 1 | — | 0 |
| 2 | 50 | 50 |
| 3 | 100 | 150 |
| 4 | 150 | 300 |
| 5 | 200 | 500 |
| 6 | 250 | 750 |
| 7 | 300 | 1050 |
| 8 | 350 | 1400 |
| 9 | 400 | 1800 |
| 10 | 450 | 2250 |
| 11 | 500 | 2750 |
| 12 | 550 | 3300 |
| 13 | 600 | 3900 |
| 14 | 650 | 4550 |
| 15 | 700 | 5250 |
| 16 | 750 | 6000 |
| 17 | 800 | 6800 |
| 18 | 850 | 7650 |
| 19 | 900 | 8550 |
| 20 | 950 | 9500 |

**Total XP to max: 9500 per companion.** With five levelable units (4 companions + protagonist), that's 47,500 XP total — reasonable for a 30–40h playthrough. Note: because XP is **consumed** on each level-up (not cumulative), the player must earn each level's cost separately.

### Gold cost per level (linear)

```
gold_cost(current_level) = 25 * current_level    # level 1..19; 0 at cap
```

| Current level | Gold cost | Running total |
|---|---|---|
| 1 → 2 | 25 | 25 |
| 5 → 6 | 125 | 375 |
| 10 → 11 | 250 | 1375 |
| 15 → 16 | 375 | 3125 |
| 19 → 20 | 475 | 4750 |

**Total gold to max: 4750 per companion.** All 5 units = 23,750 gold. Combined with the gift-items shop, gold remains meaningful throughout the campaign.

### Manual level-up action

Leveling up is **NOT automatic**. The player opens the Companion Room detail panel, sees a "Level Up" button that shows the XP + gold cost for the next level, and taps it to spend both resources. The button is disabled (greyed) until both costs are affordable.

```
can_level_up(id) =
    level < LEVEL_CAP
    AND banked_xp(id) >= xp_cost(current_level)
    AND player_gold >= gold_cost(current_level)

level_up_companion(id):
    if not can_level_up(id): return false
    banked_xp(id)  -= xp_cost(current_level)
    player_gold    -= gold_cost(current_level)
    level(id)      += 1
    return true
```

### Per-level stat bonuses

Applied additively on top of base stats, before blessings:

```
hp_bonus(level)          = (level - 1) * 6
atk_bonus(level)         = (level - 1) * 1
def_bonus(level)         = (level - 1) / 2          (integer div, rounded down)
agi_bonus(level)         = (level - 1) / 5          (integer div)
crit_chance_bonus(level) = ((level - 1) / 5) * 1.0  (percentage points; every 5 levels)
crit_dmg_bonus(level)    = ((level - 1) / 10) * 5.0 (percentage points; every 10 levels)
```

Lvl 1 = baseline, lvl 20 caps at:

| Stat | Base (Artemis) | +Lvl 20 bonus | Max |
|---|---|---|---|
| HP | 95 | +114 | 209 |
| ATK | 22 | +19 | 41 |
| DEF | 8 | +9 | 17 |
| AGI | 20 | +3 | 23 |
| Crit% | 10.0 | +3.0 | 13.0 |
| CritDmg | 170 | +5 | 175 |

Artemis roughly doubles in HP and ATK at max, with small bumps to DEF/AGI/crit. Bosses also scale up, so the fight stays difficult if the player skips grinding.

Milestone levels (5, 10, 15, 20) give AGI / crit bumps — these are the "feel" moments where a level-up is visibly different.

## XP sources

| Source | Amount | Scope | When | Notes |
|---|---|---|---|---|
| Combat victory | 30 XP | Every surviving party member + protagonist | `battle_ended(true)` | Existing `BattleManager.battle_ended` signal |
| Combat participation (dead) | 10 XP | Every party member who fell | `battle_ended(true)` | Even KO'd members learn from the fight |
| Exploration mission | 5–60 XP | Dispatched companion only | `exploration.gd` completion | Already implemented (STORY-EXPLORE-005) |
| Chapter completion | 100 XP | Every companion the player has met | Chapter-final dialogue node | New — wired through the `"meet"`-effect pipeline |
| Tavern tournament win | 20 XP | Protagonist + active party | Tavern results screen | Minor bonus, not the main source |

Combat is the primary engine. A player who fights 10 battles in a session earns 300 XP per companion (level 5–6 range).

## Data

No schema changes to `GameStore._companion_xp` — it's already `Dictionary{id: int}`. New helpers:

```gdscript
func get_companion_level(id: String) -> int
func get_xp_into_current_level(id: String) -> int
func get_xp_needed_for_next_level(id: String) -> int  # returns 0 at cap
```

Protagonist uses id `"protagonist"` in the same dict. No special case.

### New RefCounted: `CompanionLevel`

Pure-logic class in `src/systems/companion_level.gd`. Static methods only:

```gdscript
static func xp_to_level(xp: int) -> int
static func xp_total_for_level(level: int) -> int
static func xp_needed_for_next(current_level: int) -> int
static func hp_bonus_for_level(level: int) -> int
static func atk_bonus_for_level(level: int) -> int
static func def_bonus_for_level(level: int) -> int
static func agi_bonus_for_level(level: int) -> int
static func crit_chance_bonus_for_level(level: int) -> float
static func crit_damage_bonus_for_level(level: int) -> float
static func apply_to_stats(stats: BattleStats, level: int) -> void
```

`apply_to_stats` mutates the BattleStats in place — same pattern as `_apply_blessing_effect`. Called from `BattleManager._apply_level_bonuses(combatant)` during `setup()`.

### Layering order in BattleManager.setup

```
1. Build combatant with base stats from character_battle_stats.json (includes current_hp = max_hp).
2. _apply_level_bonuses(combatant)   # level scaling  (this spec)
3. _apply_blessings_to(combatant)    # romance-gated blessings
4. _apply_gun_element()              # protagonist's socket element
```

Blessings come after levels so a "+4 ATK" blessing at stage 1 still feels meaningful against a leveled-up baseline.

After `apply_to_stats` bumps max_hp, `current_hp` is snapped to the new max — matching the existing blessing pattern so the companion enters battle at full HP.

## UI

### Companion Room detail panel
- New row above the "Relationship: Lvl X" line: **"Level X · 150 / 200 XP"**
- Progress bar below the text, width 80% of the detail panel
- Level number is gold accent; XP text is secondary
- Tapping the bar opens a tooltip listing the next-level bonuses

### Deck screen grid cards
- Small "Lv X" badge in the top-right corner of each card
- Only shown for met companions
- Protagonist card shows his own level

### Battle HUD actor name
- `"Hero · Lv 5"` instead of just `"Hero"`
- `"Artemis · Lv 3  [Blessings: 1]"` — level slots between name and blessings tag
- Updates on `turn_started` via existing `_refresh_actor_hud`

### No dedicated "level up!" popup in v1
- Level-ups happen silently — the player notices next time they see the companion screen or enter a battle.
- A celebration popup is future polish work (Phase H+) if playtests show it's missed.

## Edge cases

- **XP at cap**: `get_xp_needed_for_next_level` returns 0 when level == 20. UI hides the bar and shows "MAX".
- **Negative XP**: `add_companion_xp(id, -5)` is not supported. Clamp to 0 in the setter.
- **New companion joins mid-game with 0 XP**: level 1, no bonuses. Immediate exploration / combat will bump her up.
- **Protagonist XP before companions exist**: works fine — the dict accepts `"protagonist"` as a key without any special handling.
- **Save migration**: pre-Phase H saves have no `_companion_xp` changes (dict already exists). Missing entries default to 0.
- **XP overflow past cap**: levels plateau at 20 but the XP counter keeps accumulating. `xp_to_level` returns 20 even for xp > threshold[20]. No overflow.
- **Level recalculation during battle**: levels are computed in `BattleManager.setup` once per encounter. Mid-battle XP grants (theoretical future feature) don't retroactively buff the current fight.

## Dependencies

- **GameStore** (`_companion_xp` already exists; new getters)
- **BattleStats** (stat mutation target)
- **BattleManager** (calls `CompanionLevel.apply_to_stats` in `setup`)
- **BattleManager.battle_ended signal** (drives post-combat XP grant — wired in `battle.gd::_on_battle_ended`)
- **CompanionLevel** (new pure-logic utility)
- **Localization** (new keys for "Level" / "XP" / "MAX")
- **companion_room.gd, deck.gd, battle.gd** (UI display)

## Tuning knobs

| Knob | Default | Safe range | Effect |
|---|---|---|---|
| `LEVEL_CAP` | 20 | 10–30 | Hard ceiling on progression |
| XP coefficient | 25 | 15–50 | Curve scale (higher = slower) |
| `hp_per_level` | 6 | 3–12 | HP scaling rate |
| `atk_per_level` | 1 | 1–3 | ATK scaling rate |
| `def_per_level` | 0.5 (every 2) | 0.25–1 | DEF scaling rate |
| `agi_per_level` | 0.2 (every 5) | 0.1–0.5 | AGI scaling rate |
| `crit_chance_per_milestone` | 1% per 5 levels | 0.5–2 | Crit rate growth |
| `crit_dmg_per_milestone` | 5% per 10 levels | 2–10 | Crit damage growth |
| `combat_victory_xp` | 30 (alive) / 10 (KO) | 10–60 / 5–20 | Main engine pace |
| `chapter_complete_xp` | 100 | 50–200 | Story milestone reward |

Every knob above lives in `src/systems/companion_level.gd` constants so designers can adjust without editing the formula code.

## Acceptance criteria

- AC-LVL-01: `CompanionLevel.xp_to_level(0)` returns 1.
- AC-LVL-02: `CompanionLevel.xp_to_level(50)` returns 2 (exact threshold).
- AC-LVL-03: `CompanionLevel.xp_to_level(49)` returns 1 (one below threshold).
- AC-LVL-04: `CompanionLevel.xp_to_level(100000)` returns 20 (far past cap, clamped).
- AC-LVL-05: `xp_total_for_level(20) == 9500`.
- AC-LVL-06: `hp_bonus_for_level(1) == 0`, `hp_bonus_for_level(20) == 114`.
- AC-LVL-07: `apply_to_stats` mutates max_hp, atk, def_stat, agi, crit_chance, crit_damage.
- AC-LVL-08: `BattleManager.setup` applies level bonuses before blessing bonuses (verified by test order).
- AC-LVL-09: Combat victory grants 30 XP to each living party member + protagonist, 10 XP to KO'd members.
- AC-LVL-10: Companion Room detail panel shows "Level X · Y / Z XP" text and a progress bar.
- AC-LVL-11: Battle HUD actor name line shows "· Lv N".
- AC-LVL-12: A companion at level 20 shows "MAX" instead of the XP bar.
- AC-LVL-13: Unit test covers the XP curve for every level from 1 to 20 (parametric sweep).
- AC-LVL-14: Battle unit tests still green (75+ → verify post-integration).
- AC-LVL-15: Full test suite still green.

## Out of scope (future work)

- Level-up celebration popup / sparkle animation
- Level-down from defeat / penalty mechanics
- Shared party XP pool (all companions level together) — intentional: each goddess has her own arc
- XP boosts from gift items or blessings
- Prestige / reset system for post-cap grinding
- Enemies leveling with the party (optional rubber-banding)
