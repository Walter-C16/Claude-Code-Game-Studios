# Epic: Divine Blessings

> **Layer**: Feature
> **GDD**: design/gdd/divine-blessings.md
> **Architecture Module**: BlessingSystem
> **Governing ADRs**: ADR-0012
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories divine-blessings`

## Overview

Divine Blessings is the mechanical bridge between Romance & Social and Poker Combat -- the system that makes Pillar 3 real by turning relationship investment into combat power. 20 unique blessings (5 per companion) inject bonus chips and multipliers into the scoring pipeline, gated by romance stage (0/1/2/4/5 slots unlocked per stage). BlessingSystem is a stateless pure function (RefCounted with static methods): deterministic, sequential (slots 1-5 in order, because Nyx Slot 4 depends on prior accumulated chips), and fast (<1ms per PLAY action). CombatSystem calls it as a black box during RESOLVE. All 20 blessings are data-driven from a single JSON config file.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Divine Blessings -- Trigger Evaluation Pipeline | BlessingSystem as stateless RefCounted with static compute(). Returns {blessing_chips, blessing_mult}. Sequential slot eval, 13 trigger types, all data-driven from blessings.json. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-divine-blessings-001 | 20 blessings (5 per companion) with per-blessing trigger conditions | ADR-0012 |
| TR-divine-blessings-002 | Slot availability gated by romance stage: 0/1/2/4/5 slots per stage | ADR-0012 |
| TR-divine-blessings-003 | Captain lock: only active captain's blessings contribute; frozen at combat start | ADR-0012 |
| TR-divine-blessings-004 | compute(hand_context) returns {blessing_chips, blessing_mult} called at RESOLVE | ADR-0012 |
| TR-divine-blessings-005 | Sequential slot evaluation order (1-5); Nyx Slot 4 depends on prior accumulated chips | ADR-0012 |
| TR-divine-blessings-006 | hand_context dict from Poker Combat: cards_played, hand_rank, suit_counts, etc. | ADR-0012 |
| TR-divine-blessings-007 | Poker Combat must track discards_used and hands_played as combat state fields | ADR-0012 |
| TR-divine-blessings-008 | All 20 blessings data-driven from config resource; no hardcoded values | ADR-0012 |
| TR-divine-blessings-009 | Blessing computation within 1ms per PLAY action | ADR-0012 |
| TR-divine-blessings-010 | Blessing VFX: subtle 0.2s icon pulse per hand; no full-screen interruption | ADR-0012 |
| TR-divine-blessings-011 | Per-card variable blessings: Artemis +8/Club, Hipolita +10/Heart, Atenea +0.8 mult/Spade, Nyx +7/Diamond | ADR-0012 |
| TR-divine-blessings-012 | hand_context must include: cards_played, hand_rank, suit_counts, current_score, hands_played, discards_used, discards_remaining, discards_allowed | ADR-0012 |
| TR-divine-blessings-013 | Blessing states: LOCKED, UNLOCKED, ACTIVE, INACTIVE_TRIGGER; transitions on romance_stage_changed and captain selection | ADR-0012 |
| TR-divine-blessings-014 | Unlock state derived from romance_stage (already persisted); no additional save data needed | ADR-0012 |
| TR-divine-blessings-015 | Combat HUD: 1-5 icons (32x32px) stacked vertically on left edge; opacity 100% triggered / 40% not | ADR-0012 |
| TR-divine-blessings-016 | Long-press on blessing icon pauses game and shows tooltip | ADR-0012 |
| TR-divine-blessings-017 | blessing_chips and blessing_mult computed fresh each PLAY; do not persist across turns | ADR-0012 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/divine-blessings.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories divine-blessings` to break this epic into implementable stories.
