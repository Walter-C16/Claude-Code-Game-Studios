# Epic: Poker Combat

> **Layer**: Core
> **GDD**: design/gdd/poker-combat.md
> **Architecture Module**: CombatSystem (scene-local Node)
> **Governing ADRs**: ADR-0007
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories poker-combat`

## Overview

Poker Combat is the core action loop of Dark Olympus. The player selects cards from a poker hand, forms poker hands (10 ranks from High Card to Royal Flush), and scores chips x mult against an enemy's HP threshold. The scoring pipeline supports 7 distinct additive and multiplicative sources injected at strict positions: base hand values, per-card chips, card enhancements (Foil/Holo/Poly), element weakness/resistance, captain stat bonuses (STR/INT), divine blessing slots, and social buffs. CombatSystem is a scene-local Node that owns the encounter lifecycle via a state machine (SETUP, DRAW, SELECT, RESOLVE, DISCARD_DRAW, VICTORY, DEFEAT) and emits `combat_completed` via EventBus. This is the largest epic in the Core layer.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Poker Combat -- Scoring Pipeline Architecture | Scene-local CombatSystem with strict ordered scoring pipeline (additive chips -> additive mult -> multiplicative mult -> floor). BlessingSystem called as black box. Hand rank table data-driven from JSON. combat_completed emitted via EventBus. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-poker-combat-001 | Standard 52-card deck (4 suits x 13 values, Ace=14); suit-element mapping locked | ADR-0007 |
| TR-poker-combat-002 | 10 poker hand ranks with defined base chips and base mult values | ADR-0007 |
| TR-poker-combat-003 | Scoring pipeline: additive chips -> additive mult -> multiplicative mult -> floor | ADR-0007 |
| TR-poker-combat-004 | Element weakness/resistance cycle with +25 chips/+0.5 mult (weakness), -15 chips (resistance) | ADR-0007 |
| TR-poker-combat-005 | Captain stat bonus: floor(STR*0.5) additive chips + (1.0 + INT*0.025) multiplicative mult | ADR-0007 |
| TR-poker-combat-006 | Card enhancements: Foil (+50 chips), Holographic (+10 mult), Polychrome (x1.5 mult); one per card | ADR-0007 |
| TR-poker-combat-007 | Combat state machine: SETUP->DRAW->SELECT->RESOLVE/DISCARD_DRAW->VICTORY/DEFEAT | ADR-0007 |
| TR-poker-combat-008 | Victory check before defeat check in RESOLVE (victory short-circuits) | ADR-0007 |
| TR-poker-combat-009 | combat_completed signal emitted with victory, score, hands_used | ADR-0007 |
| TR-poker-combat-010 | Score unbounded (64-bit integers or sufficient float precision) | ADR-0007 |
| TR-poker-combat-011 | Deck exhaustion at DRAW (0 cards) = auto-defeat; < 5 cards = reduced hand | ADR-0007 |
| TR-poker-combat-012 | Social buff integration: social_buff_chips + social_buff_mult read at combat start | ADR-0007 |
| TR-poker-combat-013 | blessing_chips and blessing_mult pipeline slots computed by Divine Blessings at RESOLVE | ADR-0007 |
| TR-poker-combat-014 | Max 4 active GPU particle emitters; max 2 animated shaders; no bloom/glow (Mobile renderer) | ADR-0007 |
| TR-poker-combat-015 | Scoring cascade animation <2 seconds total; per-card 100ms resolution | ADR-0007 |
| TR-poker-combat-016 | Card sorting toggle: by Value or by Suit; display-only | ADR-0007 |
| TR-poker-combat-017 | Enemy config validation: hands_allowed >= 1, score_threshold >= 1 at data load | ADR-0007 |
| TR-poker-combat-018 | Combat state NOT persisted; outcomes only persisted via autoload stores | ADR-0007 |
| TR-poker-combat-019 | Per-card chips formula: 2-10=face value, J/Q/K=10, Ace=11 | ADR-0007 |
| TR-poker-combat-020 | Element cycle: Fire > Earth > Lightning > Water > Fire | ADR-0007 |
| TR-poker-combat-021 | total_chips clamped to min 1; additive_mult clamped to min 1.0 | ADR-0007 |
| TR-poker-combat-022 | Flush and Straight require exactly 5 cards; fewer-card plays max at Four of a Kind | ADR-0007 |
| TR-poker-combat-023 | A-2-3-4-5 wheel recognized as valid Straight | ADR-0007 |
| TR-poker-combat-024 | Discard 1-5 cards (0 invalid); replacements drawn immediately; decrement discards_remaining | ADR-0007 |
| TR-poker-combat-025 | Social buff consumed on victory (combats_remaining - 1), retained on defeat | ADR-0007 |
| TR-poker-combat-026 | Enemy config includes hands_allowed (default 4) and discards_allowed (default 4) | ADR-0007 |
| TR-poker-combat-027 | Signature cards tagged with companion_id but play identically to normal cards | ADR-0007 |
| TR-poker-combat-028 | Combat screen layout: Enemy Info (0-120px), Scoring Tray (120-420px), Hand Area (420-800px), Action Bar (800-932px) | ADR-0007 |
| TR-poker-combat-029 | Card size 64x90px minimum tap target in hand area; PLAY/DISCARD buttons 190x56px | ADR-0007 |
| TR-poker-combat-030 | HP bar: full-width, 8px height, red fill + gold score overlay with 600ms ease-out animation | ADR-0007 |
| TR-poker-combat-031 | Score numbers use tabular/monospace figures (no layout shift during counting) | ADR-0007 |
| TR-poker-combat-032 | Element icons pair color with shape (flame, drop, leaf, bolt) -- color never sole indicator | ADR-0007 |
| TR-poker-combat-033 | Two-layer dynamic BGM: base drone always, tension drum scales with hands_remaining | ADR-0007 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/poker-combat.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories poker-combat` to break this epic into implementable stories.
