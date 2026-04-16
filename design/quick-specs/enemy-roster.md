# Quick Design Spec: Enemy Roster (Action Combat)

> **Type**: Combat balance reference
> **Author**: game-designer
> **Created**: 2026-04-15
> **Cross refs**: design/quick-specs/companion-battle-stats.md (party baseline), design/quick-specs/turn-timer.md (timer assignments), design/gdd/enemy-data.md (parent registry GDD)
> **Sources of truth**: `src/assets/data/enemies.json` (registry), `src/assets/data/character_battle_stats.json` (combat stats), `src/assets/data/battle_movesets.json` (moves)

---

## Problem

The action combat roster shipped in Phase F with only 4 functional enemies (`forest_monster`, `mountain_beast`, `amazon_challenger` — which was actually missing its moveset — and `gaia_spirit`). One Fire poker reskin (`sardis_card_master`) existed but had no combat moveset. The roster covered only Earth and Fire, left Water and Lightning unrepresented, and offered only one boss encounter across the entire post-tutorial game.

This made encounter design brittle: designers couldn't build mixed-element fights that exercise elemental reactions, tutorial pacing had no mid-tier filler, and no Chapter 2+ boss existed.

## Solution

Expand the roster to 16 combatants (5 existing + 10 new + 1 fix) covering all four elements at three difficulty tiers (mook / elite / boss) and wire each enemy into the Phase F/G systems (AI profiles, turn timers, move effects). Cross-file drift between `enemies.json`, `character_battle_stats.json`, and `battle_movesets.json` is guarded by a new `enemy_roster_test.gd` integration test.

## Stat table

### Mooks (chapter 1–2 filler)

| ID | Element | HP | ATK | DEF | AGI | Crit% | AI | Timer | Moves with effects |
|---|---|---|---|---|---|---|---|---|---|
| `forest_monster` | Earth | 60 | 12 | 4 | 8 | 3 | aggressive | 0 | — |
| `cave_bat` | Water | 65 | 13 | 5 | 16 | 6 | aggressive | 0 | — |
| `thunder_imp` | Lightning | 75 | 16 | 6 | 22 | 12 | aggressive | 30 | — |
| `mountain_beast` | Earth | 120 | 20 | 10 | 10 | 5 | berserker | 45 | — |
| `magma_hound` | Fire | 130 | 22 | 11 | 14 | 8 | berserker | 30 | **pierce_def** (special) |
| `river_drake` | Water | 135 | 19 | 13 | 13 | 7 | tactical | 45 | — |
| `amazon_challenger` | Fire | 160 | 24 | 14 | 15 | 12 | tactical | 30 | — (Chapter 2+ — combat stats shipped ahead of encounter wiring) |
| `obsidian_guardian` | Earth | 170 | 18 | 18 | 10 | 4 | defensive | 45 | **party_shield_30_percent** (special) |

### Elites (duel-tier mid-bosses)

| ID | Element | HP | ATK | DEF | AGI | Crit% | AI | Timer | Moves with effects |
|---|---|---|---|---|---|---|---|---|---|
| `shade_walker` | Water | 190 | 26 | 11 | 17 | 10 | tactical | 30 | **dispel_enemy_buffs** (special) |
| `storm_harpy` | Lightning | 200 | 24 | 12 | 20 | 14 | tactical | 30 | — |

### Bosses (one per element, one per chapter)

| ID | Element | HP | ATK | DEF | AGI | Crit% | AI | Timer | Ultimate effect | Chapter |
|---|---|---|---|---|---|---|---|---|---|---|
| `gaia_spirit` | Earth | 320 | 28 | 18 | 11 | 8 | tactical | 60 | **corrupted_bloom** (DoT all party) | 1 |
| `poseidon_echo` | Water | 300 | 28 | 16 | 12 | 9 | tactical | 60 | **apply_hunter_mark_2_turns** | 2 |
| `hephaestus_remnant` | Fire | 320 | 30 | 18 | 11 | 11 | berserker | 60 | **guaranteed_crit_3_turns** (self) | 3 |
| `zeus_fragment` | Lightning | 340 | 32 | 15 | 14 | 13 | aggressive | 45 | **ignore_defense** (single-target judgment) | 4 |

### Other

| ID | Element | HP | Type | Notes |
|---|---|---|---|---|
| `sardis_card_master` | Fire | 140 | Duel | Poker-only reskin for the tavern tournament. No action-combat moveset — not spawned in normal fights. |

## Identity cards

### New Chapter 2 mooks

- **cave_bat** — Tutorial-tier Water opponent. The first enemy the player meets underground. Fast and squishy, pushes the player to try out Nyx's water element.
- **thunder_imp** — Speed demon. AGI 22 means it often out-speeds Artemis. Low HP so it can't trade, but its 30s timer exists to train the player that Lightning enemies ARE supposed to feel rushed.
- **magma_hound** — Berserker brute. Uses pierce_def on its special (Cinder Fang), which punishes high-DEF parties. Flavor: "Atenea's shield doesn't save you from its teeth."
- **river_drake** — First mid-HP Water enemy. Tactical AI picks the highest-ATK ally, so it goes for Hipolita. Paired well with `cave_bat` swarms for AoE pressure.
- **obsidian_guardian** — Tanky Earth support. Casts `party_shield_30_percent` on its allies, extending multi-enemy fights. Defensive AI means it favors the shield over attacking, so it's a "remove threat first" design.

### Chapter 3 elites

- **storm_harpy** — Aerial elite. 14% crit combined with a tactical AI that targets Hipolita means crits will land. Gale Scream is an AoE Lightning move — pair with a `thunder_imp` for reliable Solar Flare reactions (Fire + Lightning) when the player has Artemis or Hipolita in the front.
- **shade_walker** — Nyx-aligned assassin who removes ally buffs with `dispel_enemy_buffs`. This is the first enemy that can erase Atenea's party shield or Hipolita's forced_crit stance. Designed to teach the player to plan around stripping.

### Bosses

- **poseidon_echo** — Chapter 2 climax. Tactical AI, 60s timer. The Maelstrom ultimate applies `apply_hunter_mark_2_turns` to all allies, so follow-up attacks from smaller enemies in the encounter are amplified. Weakness: Earth reactions (Life Spring heal).
- **hephaestus_remnant** — Chapter 3 climax. Berserker AI scales its aggression as HP drops. The Anvil Stance ultimate is a self-buff — forces the player to interrupt mid-fight or absorb 3 turns of guaranteed crits. Weakness: Water reactions (Oracle Mist damage buff flipped against him).
- **zeus_fragment** — Chapter 4 climax. Aggressive AI, shorter timer (45s) to reinforce his "lightning" theme. Sky King's Judgment is a single-target `ignore_defense` ultimate — Atenea's 16 DEF does nothing against it, punishing tank-focused parties. Weakness: Water chain reactions (Tidal Surge).

## Balance rules used

1. **HP bands**: Mooks 60–170, Elites 180–220, Bosses 280–360. The mook ceiling overlaps the elite floor because Chapter 2 mid-mooks should still threaten a Chapter 3 party at lower levels.
2. **ATK scales with HP** such that a mook can kill a 95 HP Artemis in ~4 turns without effects. Bosses can kill her in ~3.
3. **DEF / 2 rule**: incoming damage is `max(1, ATK − DEF/2)`. Mook DEF stays under 14 so blessings remain impactful; elites and bosses have 15+ DEF to force elemental tactics.
4. **AGI bands**: mooks 8–16, elites 17–22, bosses 11–14. Bosses are slower to give players a reliable interrupt window against their ultimates.
5. **Crit chance**: caps at 14% for non-boss, 13% for bosses. Prevents one-shot lethal spikes from RNG.
6. **Timer**: assigned per lore-speed. Bosses default to 60s for drama, elites 30s for tension, brutes 45s, tutorials 0s. See turn-timer.md.
7. **AI profile**: each element has at least one entry for each of the four AI profiles across the roster, so element-vs-element matchups are never mechanically identical.

## Dependencies

- **BattleManager** — reads the stat block via `BattleStats.from_dict`; reads movesets via `CompanionRegistry` pipeline.
- **BattleAi** — consumes `ai_profile`.
- **BattleTurnTimer** — consumes `turn_timer_seconds`.
- **EnemyRegistry** — reads `enemies.json` for name + portrait + chapter gating.
- **Localization** — every `name_key` and `MOVE_ENEMY_*` string.
- **Chapter data** — future chapter JSONs reference these ids by `chapter_id` for encounter gating.

## Validation: integration test

`src/tests/unit/battle/enemy_roster_test.gd` runs on every CI pass and checks:

- AC-ROSTER-01: Every enemy with combat stats is registered in `enemies.json`.
- AC-ROSTER-02: Every enemy with combat stats has a moveset in `battle_movesets.json` (except `sardis_card_master`, which is poker-only and intentionally exempt).
- AC-ROSTER-03: Every moveset contains at least `normal` and `special`.
- AC-ROSTER-04: Every enemy uses a valid `ai_profile` from the 4-value set.
- AC-ROSTER-05: Every enemy has `turn_timer_seconds >= 0`.
- AC-ROSTER-06: Every move effect string is in the set recognized by `BattleManager._apply_effect`.
- AC-ROSTER-07: Every enemy's `has_ultimate` flag matches whether its moveset actually defines an `ultimate` block.
- AC-ROSTER-08: Every enemy `name_key` localizes to a non-empty English string (catches typos and missing i18n entries).
- AC-ROSTER-09: Every move `name_key` localizes to a non-empty English string.

Any future roster addition must pass these 9 checks — adding an enemy without its moveset or without its i18n key fails CI loudly.

## Tuning knobs

| Knob | Where | Effect |
|---|---|---|
| HP / ATK / DEF values | `character_battle_stats.json` | Per-enemy difficulty |
| `turn_timer_seconds` | `character_battle_stats.json` | Per-enemy urgency |
| `ai_profile` | `character_battle_stats.json` | Behavior personality |
| `damage_mult` on moves | `battle_movesets.json` | Per-move swing |
| `effect` string on moves | `battle_movesets.json` | Special mechanics |
| `chapter` field | `enemies.json` | Encounter gating |
| `context` field | `enemies.json` | Writer hint / docs |

## Acceptance criteria

- AC-ROSTER-A: 10 new enemies are added across 4 elements (at least 2 per element).
- AC-ROSTER-B: 3 new bosses exist, one each for Water, Fire, Lightning (Earth already had gaia_spirit).
- AC-ROSTER-C: amazon_challenger now has a valid moveset (regression fix).
- AC-ROSTER-D: All 9 integration tests in `enemy_roster_test.gd` pass.
- AC-ROSTER-E: Battle unit test suite remains green (75/75 after this work).
- AC-ROSTER-F: Full unit test suite remains green (624/624 after this work; was 615/615).
