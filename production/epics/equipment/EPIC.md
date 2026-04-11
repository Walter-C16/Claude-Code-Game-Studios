# Epic: Equipment

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/equipment.md
> **Architecture Module**: EquipmentSystem (autoload or scene-local; injects into CombatSystem at SETUP)
> **Governing ADRs**: ADR-0007 (scoring pipeline injection point Step 4/D)
> **Status**: Ready
> **Stories**: 8 stories — see stories.md

## Overview

Equipment is a two-slot passive stat-bonus system. The Weapon slot applies an additive `chip_bonus` and the Amulet slot applies an additive `mult_bonus` to the poker scoring pipeline at Step 4 (after captain, before blessings). Items have three rarities (Common, Rare, Legendary) with defined bonus ranges. Items are data-driven from `assets/data/equipment.json`. Players obtain items from standard combat drops (20% rate, rarity weighted), boss guarantees (100%, Rare floor), exploration returns, and Abyss shops. Equipping replaces the current slot item — no storage beyond the active item. A `pending_equipment` queue (max 5) holds unequipped items awaiting player decision. The Equipment screen is accessible from Camp and from the Abyss between-ante shop, but never during active combat.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Poker Combat — Scoring Pipeline Architecture | Equipment bonuses injected at strict positions: weapon_chip_bonus at Step 4 (chips additive phase), amulet_mult_bonus at Step D (mult additive phase). Both read once at SETUP and locked for combat duration. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-equip-001 | Two slots: Weapon (chips additive) and Amulet (mult additive) | ADR-0007 |
| TR-equip-002 | Rarity tiers: Common (65%), Rare (30%), Legendary (5%) with defined bonus ranges | New |
| TR-equip-003 | Scoring pipeline injection: weapon_chip_bonus at Step 4; amulet_mult_bonus at Step D | ADR-0007 |
| TR-equip-004 | Items data-driven from assets/data/equipment.json; no hardcoded bonus values | New |
| TR-equip-005 | Equip action replaces current slot item; replaced item discarded (not returned to inventory) | New |
| TR-equip-006 | Equipment screen shows before/after comparison before confirming replacement | New |
| TR-equip-007 | pending_equipment queue max 5 items; acquisition beyond cap discards new item with notification | New |
| TR-equip-008 | Standard combat drop: 20% rate on win; rarity from weighted table | New |
| TR-equip-009 | Boss combat drop: 100% guaranteed; Rare floor | New |
| TR-equip-010 | Equipment stats read once at combat SETUP; locked for encounter duration | ADR-0007 |
| TR-equip-011 | Empty slot contributes 0 / 0.0 to pipeline; no crash | ADR-0007 |
| TR-equip-012 | equipment.json load failure defaults both bonuses to 0; logs error; does not block combat | New |
| TR-equip-013 | Equipment screen accessible from Camp and Abyss shop; NOT during active combat | New |
| TR-equip-014 | Pending inventory warning shown at 4/5 items (pre-full) | New |
| TR-equip-015 | All tuning knobs in assets/data/equipment_config.json | New |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment.md` are verified (AC-1 through AC-7)
- All Logic and Integration stories have passing test files in `tests/`
- All UI stories have evidence docs in `production/qa/evidence/`
- Integration with CombatSystem scoring pipeline verified via seeded test hand

## Next Step

Stories are defined in `production/epics/equipment/stories.md`.
