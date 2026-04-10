# Enemy Data

> **Status**: In Design
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-08
> **Implements Pillar**: Pillar 1 — Balatro-Inspired Poker Combat

## Summary

Enemy Data is the central registry for all combat opponents in Dark Olympus. It defines enemy profiles (name, HP, score threshold, element affinity, chapter context) consumed by Poker Combat for challenge scaling and by Story Flow for combat node configuration. Currently 4 Chapter 1 enemies are defined, with ~16 additional enemy names reserved for Chapter 2+ content.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Enemy Data defines the schema for all combat opponents the player faces. Each enemy has a static profile specifying its name (via translation key), HP pool, score threshold (the target the player must reach), optional element affinity, and the story context where it appears. The Poker Combat system reads these profiles to configure each encounter; Story Flow embeds enemy configs in chapter nodes to link narrative progression to combat challenges. This system does not implement combat logic -- it provides the enemy contracts that combat consumes.

## Player Fantasy

Every enemy is a named threat with a mythological identity. The Forest Monster is a warm-up; the Cyclops is a wall. When the player sees "Gaia Spirit -- 250 HP" they should feel a mixture of dread and excitement -- *can my deck handle this?* The enemy data system succeeds when each enemy name triggers a distinct emotional response: the tutorial enemy feels safe, the chapter boss feels like a real fight, and the duel against Hipolita feels personal rather than mechanical. Enemies are the measuring stick for the player's growing mastery of the poker-combat system.

## Detailed Design

### Core Rules

#### Enemy Registry

Each enemy has a static profile. Enemies are not created at runtime -- they are defined in data and instantiated by the combat system when a story node or Abyss encounter triggers a fight.

**Chapter 1 Enemies:**

| ID | Name Key | Display Name | HP | Score Threshold | Element | Context | Type |
|----|----------|-------------|-----|----------------|---------|---------|------|
| `forest_monster` | ENEMY_FOREST_MONSTER | Forest Monster | 40 | 40 | None | Prologue tutorial | Normal |
| `mountain_beast` | ENEMY_MOUNTAIN_BEAST | Mountain Beast | 80 | 50 | None | Mountain ambush | Normal |
| `amazon_challenger` | ENEMY_AMAZON_CHALLENGER | Amazon Challenger | 80 | 50 | Fire | Amazon challenge | Duel |
| `gaia_spirit` | ENEMY_GAIA_SPIRIT | Gaia Spirit | 250 | 130 | Earth | Night siege boss | Boss |

**Reserved enemy names (Chapter 2+, not yet configured):**
Temple Beast, Cyclops, Shadow Minion, Shade Warrior, Shadow Beast, Amazon Guardian, Corrupted Amazon, Stone Golem, Temple Guardian, Echo of Cronos, Titan Vanguard, Titan Centurion, Shadow of Cronos, Ancient Specter, Corrupted Shadow, Corrupted Beast.

**Rules:**
1. Each enemy has a unique string ID used as the lookup key.
2. `name_key` is a translation key referencing `i18n/en.json` for the display name.
3. `hp` is the enemy's total health pool. In story combat, this equals the player's score target.
4. `score_threshold` is the minimum score the player must accumulate across all hands to defeat the enemy. For most enemies, `score_threshold` <= `hp`. The threshold exists separately to allow multi-phase enemies (future: phase 1 threshold, phase 2 threshold).
5. `element` is optional. If set, the enemy takes bonus damage from the opposing element and resists its own. If `None`, element has no effect.
6. `type` categorizes the encounter: `Normal` (standard story fight), `Boss` (chapter climax, higher HP), `Duel` (friendly/narrative fight with special rules), `Abyss` (procedurally scaled for roguelike mode).
7. Abyss mode does NOT use the enemy registry directly. Abyss encounters use a separate scaling formula (defined in the Abyss Mode GDD) that generates score targets procedurally. The enemy registry is for story-defined encounters only.

#### Enemy Profile Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique kebab-case identifier |
| `name_key` | String | Yes | i18n translation key for display name |
| `hp` | int | Yes | Total health pool / score target |
| `score_threshold` | int | Yes | Minimum score to defeat (usually <= hp) |
| `element` | Element? | No | Element affinity (Fire/Water/Earth/Lightning or null) |
| `chapter` | String | Yes | Chapter where this enemy appears (e.g., "chapter_1") |
| `context` | String | Yes | Narrative context description |
| `type` | EnemyType | Yes | Normal / Boss / Duel / Abyss |
| `attack` | int | No | Derived: `floor(hp * 0.1)`. Used if enemy-turn damage is implemented. |
| `portrait_key` | String | No | Asset path for enemy portrait (if visual exists) |

### States and Transitions

Enemy Data itself is stateless -- it is a read-only data layer. Enemy *instances* during combat have state (current HP, active effects), but that state is owned by the Poker Combat system, not by Enemy Data.

### Interactions with Other Systems

| System | Direction | Data Flow |
|--------|-----------|-----------|
| **Poker Combat** | Depends on this | Reads enemy profile (hp, score_threshold, element, attack) to configure combat encounters. Creates enemy instances from profiles. |
| **Story Flow** | Depends on this | Embeds `enemy_config` in chapter nodes. Reads enemy profiles by ID to configure combat nodes. |
| **Abyss Mode** | Soft dependency | May read enemy names/portraits for flavor, but generates score targets procedurally. Does not depend on HP values from this registry. |
| **Localization** | This depends on Localization | Enemy display names are translation keys, not raw strings. |

## Formulas

### Attack Derivation

```
attack = floor(hp * ATTACK_RATIO)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `hp` | int | [40, 500+] | Enemy profile | Enemy health pool |
| `ATTACK_RATIO` | float | 0.1 | Balance config | Ratio of HP used as attack value |

**Output range:** 4 (Forest Monster) to 25+ (Gaia Spirit at 250 HP)
**Example:** Gaia Spirit hp=250, attack = floor(250 * 0.1) = 25.

> Note: The `attack` field is derived and currently unused in combat (poker combat is score-based, not turn-based damage). It exists as a forward-compatible field for potential enemy-turn mechanics.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| **If `score_threshold` > `hp`** | Clamp `score_threshold` to `hp`. Log a data warning. | Threshold cannot exceed total HP -- the player would need to "overkill" to win. |
| **If `hp` is 0 or negative** | Treat as instant victory. Log a data error. | Invalid data should not crash combat; degrade gracefully. |
| **If `element` is set to an invalid value** | Default to `None` (no element affinity). | Forward-compatibility for potential new elements. |
| **If an enemy ID is referenced by Story Flow but not in the registry** | Combat system uses the inline `enemy_config` from the story node. Log a warning. | Current implementation already works this way -- configs are inline in chapters.json. |
| **If a `name_key` has no translation** | Display the raw key (e.g., "ENEMY_CYCLOPS") as fallback. | Missing translations shouldn't block combat. |
| **If Chapter 2 enemies are loaded but Chapter 2 content isn't installed** | Enemies exist in the registry but are never referenced by story nodes. No impact. | Registry is additive; unused entries cost nothing. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| **Poker Combat** | Depends on this | Hard -- combat cannot configure encounters without enemy profiles |
| **Story Flow** | Depends on this | Hard -- chapter nodes reference enemy IDs for combat encounters |
| **Abyss Mode** | Soft dependency | Reads enemy names/portraits for flavor; generates its own score targets |
| **Localization** | This depends on Localization | Soft -- enemy names use translation keys; combat works with raw keys as fallback |
| **Companion Data** | References (no dependency) | Element enum is defined in Companion Data GDD; this system uses the same enum values |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| Enemy HP values (per enemy) | 40-250 (Ch1) | [20, 1000] | Harder encounters; requires better poker hands or more hands per fight | Easier encounters; risk of trivial combat |
| Score threshold ratio | Varies (0.5-1.0 of HP) | [0.3, 1.0] | Higher threshold = must score closer to full HP | Lower threshold = easier victory condition |
| `ATTACK_RATIO` | 0.1 | [0.05, 0.25] | Enemy hits harder (if enemy-turn mechanic is added) | Enemy hits softer |
| Boss HP multiplier (implicit) | ~3-5x normal | [2x, 10x] | Boss fights last longer; more poker strategy required | Boss fights feel like normal encounters |

## Acceptance Criteria

- [ ] **GIVEN** enemy ID "mountain_beast", **WHEN** queried from the registry, **THEN** returns profile with hp=80, score_threshold=50, element=None, type=Normal.
- [ ] **GIVEN** enemy "amazon_challenger", **WHEN** queried, **THEN** element is Fire and type is Duel.
- [ ] **GIVEN** enemy with hp=250, **WHEN** attack is derived, **THEN** attack = floor(250 * 0.1) = 25.
- [ ] **GIVEN** a story node with `enemy_config: { name_key: "ENEMY_TEMPLE_BEAST", hp: 80, score_threshold: 50 }`, **WHEN** combat initializes, **THEN** combat uses hp=80 and score_threshold=50.
- [ ] **GIVEN** enemy with score_threshold > hp in data, **WHEN** loaded, **THEN** score_threshold is clamped to hp.
- [ ] **GIVEN** enemy name_key "ENEMY_CYCLOPS", **WHEN** displayed, **THEN** shows localized string "Cyclops" (not the raw key).
- [ ] **GIVEN** Chapter 2 enemy entries in the registry, **WHEN** only Chapter 1 is playable, **THEN** Chapter 2 enemies are never instantiated and cause no errors.
- [ ] All enemy HP values, thresholds, and elements are data-driven -- no hardcoded values in combat logic.
- [ ] Performance: Enemy lookup completes within 1ms.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should enemies have element affinity that creates weakness/resistance interactions with card suits? | game-designer | Before Poker Combat GDD | Currently only Hipolita (Fire) and Gaia Spirit (Earth) have elements. Design the combat interaction rule. |
| Will enemy-turn damage (the `attack` field) ever be used, or is combat purely score-based? | game-designer | Before Poker Combat GDD | If score-only, remove `attack` field to avoid confusion. |
| Should Abyss mode reuse story enemy portraits/names, or have its own procedural enemy set? | game-designer | Before Abyss Mode GDD | Affects art asset requirements. |
| What HP range should Chapter 2 enemies use? | game-designer + systems-designer | Before Chapter 2 content | Must create a difficulty curve that bridges Ch1 boss (250) to Ch2 opening. |
