# Quick Design Spec: Forge of Hephaestus (Equipment Gacha)

> **Type**: Equipment + forge fragment gacha
> **Author**: game-designer
> **Created**: 2026-04-15
> **Status**: **DESIGN ONLY (v1)** — runtime is deferred to v2. v1 ships only the design doc + greyed-out Hub button.
> **Cross refs**: design/quick-specs/oracle-gacha.md (shares the weekly cap), design/gdd/equipment.md (parent system)

---

## Problem

The companion gacha (Oracle) gives the player a way to acquire and progress goddesses. Equipment has no parallel acquisition path — it is tracked in `equipped_weapon` / `equipped_amulet` on GameStore but never actually granted in-game. Players need a long-term gold sink for equipment that mirrors the Oracle's pacing without competing for the same currency or progression slots.

## Solution

**The Forge of Hephaestus** is a second Hub location that consumes gold and grants equipment items + **forge fragments**. Forge fragments are a tier-up consumable: 5 fragments upgrade an existing piece of equipment by one tier. The Forge shares the Oracle's **30-pull weekly cap** so the two gachas force a tradeoff — players cannot stack progression by spending freely on both.

Lore framing: *"Hephaestus's hammer still beats the embers below Olympus. Pay tribute, and what comes from the forge is shaped by the will of the gods."*

## Currency

| Currency | Source | Notes |
|---|---|---|
| **Gold** | Same pool as Oracle | Single-currency design. |

## Pulls

| Pull type | Cost | Result |
|---|---|---|
| **Single** | 30 gold | 1 equipment roll |
| **Ten-pull** | 270 gold (10% discount) | 10 equipment rolls + 1 guaranteed Uncommon |

### Single-roll outcome table

| Roll | Probability | Result |
|---|---|---|
| Common | 70% | 3-5 forge fragments (uniform random in that range) |
| Uncommon | 25% | 1 random Uncommon equipment piece |
| Rare | 5% | 1 random Rare equipment piece |

There is no "Legendary" tier on the Forge — equipment power scales through tier-up consumption of forge fragments, not through rarer drops.

## Equipment pool (v2 — STUBBED in v1)

The actual equipment list is **out of scope for this gacha spec**. It depends on the Equipment GDD (`design/gdd/equipment.md`) which has not been updated for action combat yet. v1 ships placeholder data only.

### Stub data shape (`src/assets/data/forge_pool.json`)

```json
{
  "config": {
    "single_cost": 30,
    "ten_cost": 270,
    "fragment_drop_min": 3,
    "fragment_drop_max": 5,
    "tier_up_fragments": 5
  },
  "outcome_table": [
    {"prob": 0.70, "type": "fragments"},
    {"prob": 0.25, "type": "equipment", "rarity": "uncommon"},
    {"prob": 0.05, "type": "equipment", "rarity": "rare"}
  ],
  "pool": {
    "uncommon": [
      {"id": "iron_sword", "slot": "weapon", "atk_bonus": 3},
      {"id": "wooden_amulet", "slot": "amulet", "def_bonus": 2}
    ],
    "rare": [
      {"id": "silver_blade", "slot": "weapon", "atk_bonus": 6, "crit_bonus": 5},
      {"id": "obsidian_amulet", "slot": "amulet", "def_bonus": 5, "hp_bonus": 20}
    ]
  }
}
```

The pool is intentionally tiny in v1 (4 items). v2 implementation expands it to 8-12 items minimum, balanced against the action combat damage formula in `companion-battle-stats.md`.

## Forge fragments

- Stack-only consumable. No quality, no element. Just a counter.
- 5 fragments tier up one existing piece of equipment by 1 tier.
- Tier scales bonuses linearly: Tier 2 = +50% over Tier 1, Tier 3 = +100%, etc.
- Maximum tier 5.
- Tier-up UI lives in the Equipment screen (out of scope for this spec).

## Weekly pull limit

The Forge **shares** the Oracle's 30-pull weekly cap. There is exactly one counter on GameStore (`_oracle_pulls_this_week`, despite the name) that both systems decrement.

| Action | Cap deduction |
|---|---|
| Oracle single pull | 1 |
| Oracle ten pull | 10 |
| Forge single pull | 1 |
| Forge ten pull | 10 |

A player who burns 30 Forge pulls cannot Oracle that week, and vice versa. This is intentional — it forces players to pick a progression focus per week.

The cap field name will likely be renamed to `_gacha_pulls_this_week` in v2 to reflect the shared use.

## UI

### Forge scene (`src/scenes/forge/forge.tscn`)

- Background: smithy with forge fire (placeholder asset).
- Header: gold balance, weekly pulls remaining (shared with Oracle), reset countdown.
- Center: Hephaestus silhouette + forge fragment counter.
- Right panel: equipment inventory preview (read-only at this screen — full editor is in Equipment).
- Bottom: two pull buttons.
  - "Single Forge · 30g"
  - "Ten Forge · 270g"

### Reveal animation

- Single: hammer strike → spark burst → result card slides in (`Fx.slide_in + Fx.gold_shimmer`).
- Ten: 10 hammer strikes in rapid sequence (1.5 sec total) then 10 cards cascade.
- Equipment cards show item name, slot, and stat bonuses.
- Fragment cards show "Forge Fragments × N" with a count-up animation.

### Hub button (v1 placeholder)

- Add `ForgeBtn` to the Hub navigation grid next to `OracleBtn`.
- v1: `disabled = true`, tooltip "Coming soon — the forge is cooling".
- Gated behind `ch01_complete` flag — same as Oracle.

## Data

### GameStore additions (v2)

```gdscript
var _forge_fragments: int = 0
var _equipment_inventory: Array = []   # array of equipment dicts {id, slot, tier, bonuses...}
```

`_oracle_pulls_this_week` and `_week_start_unix` already exist from the Oracle spec — they are shared.

## Formulas

### Pull cost validation

```
can_forge_single(gold, pulls_this_week) =
    gold >= 30 AND pulls_this_week < 30

can_forge_ten(gold, pulls_this_week) =
    gold >= 270 AND pulls_this_week + 10 <= 30
```

### Tier-up cost

```
fragments_required_for_tier_up = 5  (constant for all equipment, all tiers, v1)
```

## Edge cases

- **Inventory full**: equipment inventory has no hard cap in v2 design. If a cap is added later, full inventory rejects equipment outcomes and converts to extra fragments instead.
- **Duplicate equipment**: rolling a piece the player already owns awards forge fragments equal to half the pull's expected fragment value (1-2 fragments). No "dust into fragments" option in v1 — automatic.
- **Save migration**: pre-Phase G saves have no `_forge_fragments` or `_equipment_inventory` fields. Defaults: 0 fragments, empty array.
- **Forge pulls draining Oracle quota**: by design. Communicate clearly in both UIs.

## Dependencies

- **GameStore** — gold balance, weekly counter (shared), forge fragments, equipment inventory.
- **Equipment GDD** (`design/gdd/equipment.md`) — needs to be updated for action combat before forge_pool.json can move beyond stub state.
- **Oracle gacha** — shares the weekly cap.
- **Hub** — new tab button.
- **SceneManager** — needs a `FORGE` scene id.

## Tuning knobs

| Knob | Default | Safe range | Effect |
|---|---|---|---|
| `single_cost` | 30 | 20–50 | Per-pull friction. Slightly higher than Oracle (25) to reflect higher item value. |
| `ten_cost` | 270 | 180–450 | Bulk discount. Default is 10% off (less generous than Oracle's 12%). |
| `fragment_drop_min` | 3 | 1–10 | Floor of common drop range. |
| `fragment_drop_max` | 5 | 3–15 | Ceiling of common drop range. |
| `tier_up_fragments` | 5 | 3–10 | Fragments needed per tier-up. |
| `outcome_table` | 70/25/5 | sum to 1 | Distribution. |

## Acceptance criteria (v2 implementation contract)

- AC-FORGE-01: Single forge pull deducts 30 gold and rolls one outcome.
- AC-FORGE-02: Pull is rejected with no state change if gold < cost.
- AC-FORGE-03: Forge pulls share the Oracle's weekly cap counter.
- AC-FORGE-04: Common outcomes grant 3-5 forge fragments uniformly.
- AC-FORGE-05: Uncommon and Rare outcomes grant equipment items added to the inventory.
- AC-FORGE-06: Distribution unit test (1000 iterations) confirms 70/25/5 within ±5%.
- AC-FORGE-07: Save round-trip preserves `_forge_fragments` and `_equipment_inventory`.
- AC-FORGE-08: Hub button is hidden when `ch01_complete` is false; greyed when true (v1).

## Implementation checklist (v2)

1. **`src/assets/data/forge_pool.json`** — populate with the Equipment GDD's full item list (depends on Equipment GDD update).
2. **`src/autoloads/game_store.gd`** — add `_forge_fragments`, `_equipment_inventory`, helpers, persistence.
3. **`src/systems/gacha/forge.gd`** — pure-logic RefCounted (mirror of `oracle.gd`).
4. **`src/scenes/forge/forge.tscn`** + **`forge.gd`** — UI scene.
5. **`src/scenes/hub/hub.gd`** — un-disable the Forge button, route press.
6. **`src/i18n/en.json`** — Forge labels and reveal copy.
7. **`src/tests/unit/gacha/forge_test.gd`** — covers AC-FORGE-01 through AC-FORGE-08.
8. **`src/.godot/global_script_class_cache.cfg`** — register `Forge`, `ForgeTest`.
9. **`design/quick-specs/forge-gacha.md`** — flip status to "Implemented".
