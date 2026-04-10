# Epic: Enemy Data

> **Layer**: Core
> **GDD**: design/gdd/enemy-data.md
> **Architecture Module**: EnemyRegistry (autoload #8)
> **Governing ADRs**: ADR-0016
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories enemy-data`

## Overview

EnemyRegistry is a read-only autoload that loads static enemy profiles from `enemies.json` at boot and exposes them through typed getter methods. It provides the enemy schema (id, name_key, hp, score_threshold, element, chapter, context, type, attack, portrait_key) consumed by Poker Combat for encounter configuration and Story Flow for chapter-based enemy filtering. Attack values are derived from HP using a configurable ratio, and all data is validated at load time with warnings for out-of-range values.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0016: EnemyRegistry -- Static Enemy Data Autoload | GDScript autoload #8 loading enemy profiles from JSON. Read-only dictionary with typed getters. Attack derived via floor(hp * ATTACK_RATIO). Load-time validation (clamp threshold, check hp, validate element/type). | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemy-data-001 | Enemy registry as static dictionary with schema: id, name_key, hp, score_threshold, element, chapter, context, type, attack, portrait_key | ADR-0016 |
| TR-enemy-data-002 | Enemy display names via Localization translation keys (ENEMY_* prefix); raw key as fallback | ADR-0016 |
| TR-enemy-data-003 | Enemy type enum: Normal, Boss, Duel, Abyss | ADR-0016 |
| TR-enemy-data-004 | Attack derivation formula: floor(hp * ATTACK_RATIO) where ATTACK_RATIO is configurable | ADR-0016 |
| TR-enemy-data-005 | Data validation: clamp score_threshold to hp if threshold > hp; treat hp <= 0 as instant victory | ADR-0016 |
| TR-enemy-data-006 | All enemy HP, thresholds, and elements data-driven from config; no hardcoded values | ADR-0016 |
| TR-enemy-data-007 | Enemy lookup within 1ms | ADR-0016 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemy-data.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories enemy-data` to break this epic into implementable stories.
