# Quick Design Spec: Companion Battle Stats (Action Combat)

> **Type**: Balance Reference — Action Combat Phase A-F
> **Author**: game-designer
> **Created**: 2026-04-15
> **Parent GDD**: design/gdd/poker-combat.md (combat shifted from poker to turn-based action; this spec is the canonical stat reference)
> **Source of truth**: `src/assets/data/character_battle_stats.json`

---

## Problem

The combat system pivoted from poker to a Pokemon-style turn-based action loop (4 vs 4 max, AGI-ordered turn queue, normal / special / ultimate moves, six elemental reactions). The five characters (protagonist + 4 goddesses) each need a distinct combat identity that is documented in one place so designers can tune balance and writers can describe each goddess accurately.

## Solution

Define every character's base battle stats, element, and ultimate-charge mechanic in a single reference table. The table mirrors the JSON one-to-one — any change to JSON should be reflected here in the same commit.

## Stat Table

| Character | Element | HP | ATK | DEF | AGI | Crit% | CritDmg | Ult source | Ult rate |
|---|---|---|---|---|---|---|---|---|---|
| **Hero** (protagonist) | Neutral¹ | 120 | 18 | 12 | 14 | 5.0 | 150 | any_action | 10 |
| **Artemis** | Earth | 95 | 22 | 8 | 20 | 10.0 | 170 | turns_passed | 20 |
| **Hipolita** | Fire | 140 | 26 | 14 | 16 | 15.0 | 180 | damage_dealt | 1 |
| **Atenea** | Lightning | 110 | 20 | 16 | 12 | 8.0 | 160 | damage_taken | 2 |
| **Nyx** | Water | 100 | 24 | 10 | 18 | 7.0 | 160 | reactions | 25 |

¹ Hero's element is Neutral by default but is overwritten at battle setup with the element of the first non-protagonist companion in the party (the "gun socket" mechanic — see `BattleManager._apply_gun_element`).

## Stat Definitions

| Stat | Range | Meaning |
|---|---|---|
| **Element** | Fire / Water / Earth / Lightning / Neutral | Determines reaction pairs. Two different elements landing on the same target trigger a named reaction (Oracle Mist, Cinder Bloom, Solar Flare, Life Spring, Tidal Surge, Stone Aegis). Neutral never reacts. |
| **HP** | 60–320 (ally band: 95–140) | Maximum hit points. KO at 0. |
| **ATK** | 10–28 (ally band: 18–26) | Base offensive stat. Feeds the damage formula. |
| **DEF** | 4–18 (ally band: 8–16) | Defensive stat. `DEF / 2` is subtracted from incoming raw damage (minimum 1). |
| **AGI** | 8–20 (ally band: 12–20) | Determines turn order. Queue is rebuilt every round, sorted DESC. Higher AGI = earlier turn. |
| **Crit%** | 3.0–15.0 | Probability per hit of rolling a critical. Rolled before damage is applied. |
| **CritDmg** | 140–180 | Critical multiplier as a percentage. 180 = 1.8× damage. |
| **Ult source** | enum (5 options) | How the unit charges its ultimate bar. See "Ultimate Sources" below. |
| **Ult rate** | 1–25 | Amount granted per source trigger. Bar caps at `max_ultimate` (100). |

## Damage Formula

```
raw       = ATK_attacker × move.damage_mult
def_sub   = DEF_target / 2          (or 0 if move.effect == "ignore_defense")
                                    (or DEF_target / 4 if move.effect == "pierce_def")
base      = max(1, raw - def_sub)
if crit:
    base *= CritDmg / 100
if hunter_mark on target:
    base *= 1 + 0.5
if damage_buff_next on attacker:
    base *= 1 + buff.magnitude / 100   (consumed)
if shield on target:
    base *= 1 - 0.30                   (per Atenea's party_shield)
final     = base                       (before take_damage clamp)
```

Worked example — Hipolita normal attack on a forest_monster (Earth, DEF 4) with no crit, no effects:

```
raw     = 26 × 1.0 = 26
def_sub = 4 / 2    = 2
base    = max(1, 26 - 2) = 24
final   = 24
```

## Ultimate Sources

Each character has exactly one charge source. This is the single most important "feel" knob — it determines how often the player gets to fire each ult and what playstyle is rewarded.

| Source | Trigger | Strategic intent |
|---|---|---|
| `any_action` | Each action the unit takes | Reliable, average pace. Hero's baseline. |
| `turns_passed` | Each round of combat (regardless of action) | Independent of damage; rewards staying alive. Artemis's "Goddess of the Hunt" patient aim. |
| `damage_dealt` | Per point of damage dealt (rate × dmg/10) | Scales with ATK. Hipolita needs to bite hard to fire her ult — rewards aggression. |
| `damage_taken` | Per point of damage absorbed | Tank role. Atenea charges as she gets hit, then unleashes Judgment when the enemy commits. |
| `reactions` | Each elemental reaction the unit triggers | Combo dependent. Nyx must pair her Water with another element on the field — encourages party diversity. |

## Tuning Notes

1. **AGI ordering** — Artemis (20) > Nyx (18) > Hipolita (16) > Hero (14) > Atenea (12). This is intentional: scout (Artemis) and assassin (Nyx) act first; tank (Atenea) acts last so she can react to the threat.
2. **HP ↔ DEF tradeoff** — Atenea has the highest DEF (16) and middling HP (110); Hipolita inverts that with HP 140 / DEF 14. This makes Atenea better against many small hits, Hipolita better against single big ones.
3. **Crit chains** — Hipolita's 15% crit + 180% critdmg lets her statistically deal `26 × 1.5 × 1.12 ≈ 44` per swing on average against DEF 8 targets. She's the designated boss-shredder.
4. **Element coverage** — One companion per primary element (Earth/Fire/Lightning/Water). Hero is Neutral until paired, so the "gun socket" choice meaningfully changes which reactions Hero can trigger.

## Constraints

- Stats must stay within the bands listed in "Stat Definitions". Anything outside breaks the damage formula assumptions or the AGI scheduling.
- Ult rates are calibrated against `max_ultimate = 100`. If `max_ultimate` ever changes globally, every ult rate has to be re-tuned.
- Crit rolls use a uniform PRNG. No pity counter — players experience natural variance.

## Acceptance Criteria

- AC-CBS-01: `src/assets/data/character_battle_stats.json` matches the table above for all 5 characters and 5 enemies (the enemy section lives in the same JSON).
- AC-CBS-02: BattleStats unit tests cover the formula path: `tests/unit/battle/battle_stats_test.gd` confirms `from_dict` round-trips every field listed here.
- AC-CBS-03: BattleManager unit tests confirm AGI sorting (`test_battle_manager_turn_queue_sorted_by_agi_descending`) and gun element propagation (`test_battle_manager_setup_gun_element_matches_first_companion`).
- AC-CBS-04: Hero's element shows the first companion's element on the battle HUD when a non-Hero ally is in slot 1.
- AC-CBS-05: This document is updated in the same commit as any change to the JSON. PRs touching the JSON without touching this doc fail review.

## Historical note: Epithets (removed 2026-04)

Earlier iterations layered **Epithet tiers (I–VI)** on top of the base stats — Epithet I was the join-the-party baseline and each subsequent tier granted passive combat bonuses (energy regen, crit chance, extra hit on special, +1 turn on buffs). Epithets were sourced from the Oracle gacha, then briefly from level thresholds, then removed entirely along with the gacha.

Current tuning intent: **base stats + level bonuses + romance-gated blessings** are the only axes of combat power. Tune base stats so the level-capped, fully-blessed version is interesting but not oppressive; there is no longer an endgame multiplier on top.

## Open Questions

- Does Nyx's `reactions` ult charge feel too punishing in solo battles where she has no party reaction partner? Validate after the first 3 playtests of Chapter 1 fights.
- Should Hero's `any_action` rate scale with party stage (e.g. unlock at romance level X)? Currently flat 10. Defer until romance stages 3+ are playable.
