# Quick Design Spec: Oracle of Delphi (Companion Gacha)

> **Type**: Companion acquisition + progression gacha
> **Author**: game-designer
> **Created**: 2026-04-15
> **Status**: **DESIGN ONLY (v1)** — runtime is deferred to v2. v1 ships only the design doc + greyed-out Hub button.
> **Parent GDD**: design/gdd/companion-data.md (R&S references companion identity)
> **Cross refs**: design/quick-specs/companion-battle-stats.md (base stats Epithets modify), design/quick-specs/forge-gacha.md (shares the weekly cap), design/quick-specs/gift-items.md (parallel gold sink)

---

## Problem

The game ships with four playable goddesses (Artemis, Hippolyta, Atenea, Nyx) but only Artemis and Hippolyta are wired into Chapter 1's `meet` story effects. Atenea and Nyx have no in-game acquisition path. Players who want to use a specific goddess must wait several chapters with no agency, and there is no long-term gold sink past the gift-item shop.

The player wants:
1. A gacha-style acquisition path so any companion can be summoned early.
2. A 6-tier progression per companion (constellation analog) named **Epithets** — each goddess in Greek myth had multiple epithets describing facets of her power, so the lore framing is authentic.
3. Story unlocks remain canonical — gacha is a parallel path, not a replacement.
4. A weekly pull cap so gold-rich players cannot insta-max everything.
5. All currency in-game (gold). No premium currency, no real money, ever.

## Solution

**The Oracle of Delphi**, presided over by the existing Priestess NPC, is a Hub location that consumes gold and grants random **Bond Shards** of the four playable goddesses. Accumulating Shards of a goddess unlocks her Epithets in order, with Epithet I = "she joins the party". Once a goddess reaches Epithet VI (max), additional Shards refund as gold so pulls are never wasted. A shared weekly pull cap (with the Forge gacha) caps player progression.

Lore framing: *"Gaia's fragments still whisper. Pay tribute at the altar and the goddess who favors you today will answer your call."*

## Currency

| Currency | Source | Notes |
|---|---|---|
| **Gold** | Story rewards, combat victories, exploration | The only currency. Single sink. |

No tokens, no shards-as-currency. Bond Shards are consumed-on-spend progression resources, not transferable currency.

## Pulls

| Pull type | Cost | Result |
|---|---|---|
| **Single** | 25 gold | 1 shard roll |
| **Ten-pull** | 220 gold (12% discount) | 10 shard rolls + 1 guaranteed bonus shard for the lowest-Epithet goddess |

### Single-roll outcome table

| Roll | Probability | Result |
|---|---|---|
| Common | 60% | 1 Bond Shard, random goddess (weighted toward lowest Epithet) |
| Uncommon | 30% | 2 Bond Shards, random goddess (same weighting) |
| Rare | 9%  | 3 Bond Shards, random goddess (same weighting) |
| Legendary | 1% | 5 Bond Shards, **player picks the goddess** |

### Least-favored weighting

The "random goddess" choice is weighted so lower-Epithet goddesses appear more often. This is implicit pity — players never feel completely abandoned.

| Current Epithet | Weight |
|---|---|
| Not yet unlocked (0) | 4 |
| Epithet I | 3 |
| Epithet II | 3 |
| Epithet III | 2 |
| Epithet IV | 2 |
| Epithet V | 1 |
| Epithet VI (max) | 0.25 (shards refund as gold) |

Example: if Atenea is at Epithet 0 (locked) and the other three are at Epithet III, Atenea has weight 4 vs 2/2/2 → 40% chance per roll.

## Epithets

Each goddess has **6 Epithets**. Each Epithet is unlocked by spending an increasing number of Bond Shards. Epithet I is the "join the party" milestone; Epithets II–VI are passive upgrades layered on top.

| Epithet | Cumulative shard cost | Shard delta | Unlock |
|---|---|---|---|
| **I — Awakening** | 5 | 5 | Companion joins party (calls existing `CompanionRegistry.meet_companion`) |
| **II — Devotion** | 8 | 3 | +1 to her per-turn energy regen (stacks with global regen) |
| **III — Vigil** | 13 | 5 | Unlocks Battle Blessing slot 4 (currently capped at slot 5 by stage 4 — this lifts that cap) |
| **IV — Apotheosis** | 20 | 7 | +5% base crit chance |
| **V — Communion** | 30 | 10 | Special move gains +1 hit |
| **VI — Eternal** | 45 | 15 | Ultimate move's effect duration +1 turn (e.g. forced_crit 3→4) |

After Epithet VI: every additional shard for that goddess auto-converts to **+15 gold** (refund into the player's pool). This keeps surplus pulls meaningful without runaway power creep.

### Story unlocks

If a companion is unlocked via story (`meet_companion` from a Chapter JSON), she starts at **Epithet I with 0 shards toward Epithet II**. Story unlock = unlock only, no free progression. Players who summoned her early via gacha keep their accumulated shards.

### Goddess names for each Epithet (writer-facing)

| Goddess | I | II | III | IV | V | VI |
|---|---|---|---|---|---|---|
| Artemis | Phoebe | Agrotera | Locheia | Potnia Theron | Cynthia | Phosphoros |
| Hippolyta | Andromache | Alkis | Areia | Athanasia | Nikephoros | Pyromachos |
| Atenea | Polias | Promachos | Ergane | Pronoia | Hygieia | Pallas |
| Nyx | Aithra | Mormo | Skotia | Lamia | Erebos | Eteria |

These names are surfaced in the Oracle reveal animation ("Artemis Agrotera answers your call!") and in the Companion Room codex.

## Weekly pull limit

- **30 pulls per week**, shared with the Forge gacha (see forge-gacha.md). A ten-pull counts as 10 toward the cap.
- Resets every **7 days from first pull of the cycle**, tracked via `_week_start_unix` on GameStore.
- When the cap is reached, the Oracle UI greys out pull buttons and shows "Return on [date]" with the reset timestamp.
- The weekly cap is the load-bearing balance dial. Without it, a player with 5,000 gold could max every Epithet in one session.
- Weekly reset check fires on Hub entry and on Oracle scene entry.

## UI

### Oracle scene (`src/scenes/oracle/oracle.tscn`)

- Background: candlelit temple interior (placeholder asset).
- Header: gold balance widget (reuse Hub's), weekly pulls remaining ("23 / 30 this week"), reset countdown.
- Center body: Priestess portrait + 4 Bond Shard counters (one per goddess) with per-goddess progress bars showing shards toward the next Epithet.
- Bottom bar: two big buttons.
  - "Single Pull · 25g" — disabled when gold < 25 OR weekly cap reached.
  - "Ten Pull · 220g" — disabled when gold < 220 OR weekly cap < 10.
- Tap Priestess portrait → Epithet codex screen showing all 4 goddesses' Epithet details and unlock requirements.

### Reveal animation

- Single pull: 1.5 second sequence — coin offering animation (gold count down), priestess raises hand, single shard card flips in with `Fx.pop_scale + Fx.gold_shimmer`. Card displays goddess portrait + Epithet name if this pull triggered a new Epithet.
- Ten pull: 4 second cascade — coins fly, then 10 (or 11 with bonus) cards flip in sequence at 0.25s intervals. Final flourish on any card that triggered a new Epithet.

### Hub button (v1 placeholder)

- Add `OracleBtn` to the Hub navigation grid next to existing tabs.
- v1: `disabled = true`, tooltip "Coming soon — the gods are still gathering".
- Gated behind `ch01_complete` flag — hidden entirely until the player finishes Chapter 1.

## Data

### `src/assets/data/oracle_pool.json` (v2)

```json
{
  "config": {
    "single_cost": 25,
    "ten_cost": 220,
    "weekly_cap": 30,
    "epithet_vi_refund_gold": 15
  },
  "epithet_costs": [5, 8, 13, 20, 30, 45],
  "weights_by_epithet": [4, 3, 3, 2, 2, 1, 0.25],
  "outcome_table": [
    {"prob": 0.60, "shards": 1, "player_pick": false},
    {"prob": 0.30, "shards": 2, "player_pick": false},
    {"prob": 0.09, "shards": 3, "player_pick": false},
    {"prob": 0.01, "shards": 5, "player_pick": true}
  ]
}
```

### GameStore additions (v2)

```gdscript
var _companion_shards: Dictionary = {}      # {companion_id: int}
var _companion_epithets: Dictionary = {}    # {companion_id: int}  highest unlocked, 0 if locked
var _oracle_pulls_this_week: int = 0
var _week_start_unix: int = 0
```

All four fields persist via `to_dict`/`from_dict`. Save migration: missing fields default to 0/empty.

### `meet_companion` integration (v2)

When a story `meet` effect fires for a goddess at Epithet 0, set her Epithet to 1 immediately. Already-unlocked-via-gacha companions are no-op for `meet_companion` (the deck-add already handles the duplicate case).

## Formulas

### Pull cost validation

```
can_single_pull(gold, pulls_this_week) =
    gold >= single_cost AND pulls_this_week < weekly_cap

can_ten_pull(gold, pulls_this_week) =
    gold >= ten_cost AND pulls_this_week + 10 <= weekly_cap
```

### Roll resolution (single pull)

```
1. Deduct single_cost gold.
2. Increment pulls_this_week by 1.
3. Roll uniform [0, 1) → select outcome row by cumulative prob.
4. If outcome.player_pick: caller supplies goddess id (UI prompt).
5. Else: weighted random pick across goddesses where
       weight[g] = weights_by_epithet[epithets[g]]
6. Add outcome.shards Bond Shards to that goddess.
7. While shards[g] >= epithet_costs[epithets[g]]:
       shards[g] -= epithet_costs[epithets[g]]
       epithets[g] += 1
       if epithets[g] == 1: meet_companion(g)
       if epithets[g] > 6:
           epithets[g] = 6
           gold += refund * shards[g]
           shards[g] = 0
           break
```

### Worked example

Player has 100 gold, Atenea at Epithet 0, Hippolyta at Epithet III, Artemis at Epithet I, Nyx at Epithet 0.

Single pull (25g):
- Gold: 100 → 75
- Roll: 0.42 → Common (60%) → 1 shard
- Weights: Atenea 4, Hippolyta 2, Artemis 3, Nyx 4 → total 13
- Roll weight: 0.7 × 13 = 9.1 → Atenea (covers 0-4), Artemis (4-7), Hippolyta (7-9), Nyx (9-13) → Hippolyta? 9.1 falls into Nyx's bucket (9-13). Result: 1 shard for Nyx.
- Nyx shards: 0 → 1. Not enough for Epithet I (5).
- End state: 75 gold, Nyx 1/5 toward Epithet I.

## Edge cases

- **All four at Epithet VI**: every pull becomes a gold-refund pull. Outcome table still rolls but the result is converted entirely to gold (+15 per shard). Player still hits the weekly cap.
- **Player picks legendary outcome on a maxed goddess**: the shards still go to that goddess, immediately convert to refund. Player should be warned in the picker UI ("She is at max — shards will refund as gold").
- **Insufficient gold mid-ten-pull**: ten-pull is atomic — if gold < ten_cost, the entire pull is rejected before any shards roll.
- **Save migration**: pre-Phase G saves have no shard fields. `from_dict` defaults missing keys to empty dicts and 0 counters.
- **Story unlock during gacha session**: if the player triggers a story `meet` for a goddess they already gacha-unlocked, it's a no-op (Epithet stays where it was).
- **Weekly reset crosses midnight**: based on `_week_start_unix + 604800`, not calendar weeks. Player's first-pull-of-the-cycle anchors the reset.
- **Clock manipulation**: setting the system clock forward triggers an early reset. Acceptable — this is a single-player game with no leaderboards. Not worth defending.

## Dependencies

- **GameStore** — gold balance, persistence, the four new fields.
- **CompanionRegistry** — `meet_companion` triggers the Epithet I unlock.
- **CompanionState** — already tracks romance level; Epithets are orthogonal.
- **BattleManager** — reads Epithet upgrades for crit/regen/blessing-slot/special-hit/ult-duration modifiers (the Epithet effects).
- **Localization** — every Epithet name + reveal copy.
- **SaveManager** — atomic flush already handles the new fields once added.
- **Hub** — new tab button.
- **Companion Battle Stats spec** — base stats that Epithets modify.
- **Forge gacha** — shares the weekly cap.

## Tuning knobs

| Knob | Default | Safe range | Effect |
|---|---|---|---|
| `single_cost` | 25 | 15–40 | Per-pull friction. Higher = slower acquisition. |
| `ten_cost` | 220 | 150–360 | Bulk discount. Default is 12% off. |
| `weekly_cap` | 30 | 20–50 | Hardest dial. Lower = longer tail on progression. |
| `epithet_costs[6]` | [5,8,13,20,30,45] | bands of ±20% | Per-Epithet shard gates. |
| `weights_by_epithet[7]` | [4,3,3,2,2,1,0.25] | each within [0.1, 5] | Pity strength. |
| `outcome_table` | 60/30/9/1 | sum to 1 | Distribution of shard counts per pull. |
| `epithet_vi_refund_gold` | 15 | 5–30 | Surplus shard refund rate. |

## Acceptance criteria (v2 implementation contract)

- AC-ORACLE-01: Player can spend 25 gold for a single pull and receive 1+ Bond Shards from a deterministic-on-test-seed RNG.
- AC-ORACLE-02: Pull is rejected with no state change if gold < cost.
- AC-ORACLE-03: Pull is rejected if `pulls_this_week >= weekly_cap`.
- AC-ORACLE-04: Reaching the cumulative shard count for Epithet I on an unlocked goddess calls `meet_companion(id)` and adds her to the deck if there's room.
- AC-ORACLE-05: Reaching Epithet VI converts all subsequent shards for that goddess into gold at the configured refund rate.
- AC-ORACLE-06: Weekly counter resets exactly 604,800 seconds after `_week_start_unix`.
- AC-ORACLE-07: Save round-trip preserves all four new fields.
- AC-ORACLE-08: Distribution unit test (1000 iterations) confirms outcome rates within ±5% of configured probabilities.
- AC-ORACLE-09: Distribution unit test confirms least-favored weighting biases pulls toward lower-Epithet goddesses.
- AC-ORACLE-10: Hub button is hidden when `ch01_complete` is false; appears greyed when true (v1) and becomes interactive (v2).

## Implementation checklist (v2)

When v2 work begins, this is the file-by-file list:

1. **`src/assets/data/oracle_pool.json`** — create with the JSON shape above.
2. **`src/autoloads/game_store.gd`** — add the four fields, helpers (`add_shards`, `get_epithet`, `set_epithet`, `consume_pull`), `_initialize_defaults`, `to_dict`, `from_dict`, `tick_weekly_reset()`.
3. **`src/autoloads/companion_registry.gd`** — extend `meet_companion` to set Epithet 1 if currently 0.
4. **`src/systems/gacha/oracle.gd`** — pure-logic RefCounted: `roll_single() -> Dictionary`, `roll_ten() -> Array[Dictionary]`, `apply_result(result) -> void`. No node access.
5. **`src/scenes/oracle/oracle.tscn`** + **`oracle.gd`** — Oracle UI scene (header, body, pull buttons, reveal animation).
6. **`src/scenes/oracle/epithet_codex.tscn`** + `.gd` — Epithet detail screen.
7. **`src/scenes/hub/hub.gd`** — un-disable the Oracle button, route press to `SceneManager.change_scene(SceneId.ORACLE)`.
8. **`src/i18n/en.json`** — Epithet names, button labels, reveal copy, error messages.
9. **`src/tests/unit/gacha/oracle_test.gd`** — covers AC-ORACLE-01 through AC-ORACLE-09.
10. **`src/.godot/global_script_class_cache.cfg`** — register `Oracle`, `OracleTest`.
11. **`design/quick-specs/oracle-gacha.md`** — flip status from "DESIGN ONLY" to "Implemented".
