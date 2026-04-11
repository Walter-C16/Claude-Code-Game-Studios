# Epic: Abyss Mode

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/abyss-mode.md
> **Architecture Module**: AbyssRunner (scene-local Node)
> **Governing ADRs**: ADR-0007 (Poker Combat scoring pipeline reuse)
> **Status**: Ready
> **Stories**: 12 stories — see stories.md

## Overview

Abyss Mode is the roguelike endgame replayability layer modeled after an escalating ante structure. The player progresses through exactly 8 antes, each with a hand-tuned score threshold (300 → 6,000). Between antes, a shop offers card removal, enhancements (Foil/Holographic/Polychrome), and temporary run buffs purchased with run-scoped gold earned per hand and per ante. Failing a threshold ends the run immediately with no retry; completing all 8 antes awards a guaranteed Legendary equipment drop. Divine blessings and equipped items carry into every run as the only persistent advantage layer. A weekly rotating modifier (read from AbyssModifiers) alters run rules each week. AbyssRunner owns the run state machine (LOBBY → ANTE → SHOP → COMPLETE/DEFEAT), delegates ante execution to CombatSystem, and persists run state through each ante via SaveManager.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Poker Combat — Scoring Pipeline Architecture | CombatSystem (scene-local Node) reused for Abyss antes; AbyssRunner constructs enemy configs per ante and delegates combat execution. combat_completed signal consumed by AbyssRunner to advance run state. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-abyss-001 | 8 antes in fixed order; score thresholds [300,500,800,1200,1800,2700,4000,6000] | ADR-0007 |
| TR-abyss-002 | hands_allowed=4, discards_allowed=4 per ante; defeat if threshold not met | ADR-0007 |
| TR-abyss-003 | Run state machine: LOBBY → ANTE → SHOP → COMPLETE/DEFEAT | New |
| TR-abyss-004 | Between-ante shop: 3 slots (removal, enhancement, or temp buff); stock generated fresh each visit | New |
| TR-abyss-005 | Shop currency is run-scoped gold; does not persist after run end | New |
| TR-abyss-006 | Gold earned: +2 per hand played, +15 per ante completed; Golden Hand buff adds +5/hand | New |
| TR-abyss-007 | Shop costs: removal=20, Foil=15, Holographic=20, Polychrome=25, buff=10–30 | New |
| TR-abyss-008 | 6 temporary run buffs with defined effects (Hunter's Focus, Divine Favor, etc.) | New |
| TR-abyss-009 | Persistent carries: active blessings + equipped weapon/amulet; run-scoped: gold, removals, enhancements, buffs | New |
| TR-abyss-010 | Run-state saved after each ante: ante_current, gold, buffs[], removals[], enhancements[], modifier_id | New |
| TR-abyss-011 | App resume from mid-run resumes from shop (or ante start); mid-hand state not saved | New |
| TR-abyss-012 | Weekly modifier locked at run start; modifier_id stored in run save; unchanged by Monday rotation mid-run | New |
| TR-abyss-013 | Full-run completion awards one equipment item at Legendary rarity floor | New |
| TR-abyss-014 | Post-run summary: antes completed, gold earned, score highscore updated win or loss | New |
| TR-abyss-015 | Score overflow soft cap at 9,999,999; display as "9,999,999+"; combat still resolves correctly | ADR-0007 |
| TR-abyss-016 | Enhancement stacking: multiple enhancements on same card are allowed | ADR-0007 |
| TR-abyss-017 | Deck resets to clean 52 cards on next run; removals/enhancements are run-scoped only | New |
| TR-abyss-018 | All tuning knobs in assets/data/abyss_config.json (no hardcoded values) | New |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/abyss-mode.md` are verified (AC-1 through AC-8)
- All Logic and Integration stories have passing test files in `tests/`
- All UI stories have evidence docs in `production/qa/evidence/`
- A full abyss run integration test passes: LOBBY → 8 antes → COMPLETE → Legendary drop

## Next Step

Stories are defined in `production/epics/abyss-mode/stories.md`.
