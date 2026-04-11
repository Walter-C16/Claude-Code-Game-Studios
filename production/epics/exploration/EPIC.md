# Epic: Exploration

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/exploration.md
> **Architecture Module**: ExplorationSystem (autoload; reads CompanionState, writes SaveManager)
> **Governing ADRs**: No dedicated ADR — implements GDD directly; SaveManager ADR governs persistence
> **Status**: Ready
> **Stories**: 7 stories — see stories.md

## Overview

Exploration is an asynchronous real-time dispatch system. From Camp, the player selects a met companion, a mission type (Hunt/Raid/Expedition/Night Watch), and a duration (1/2/4 hours). The companion is locked as dispatched for that real-world duration. On collection, rewards are computed: gold and XP scaled by duration multiplier, with a single item find roll scaled by companion AGI (item find chance) and companion INT (rarity shift). Only one dispatch may be active at a time. The dispatched companion is unavailable for Camp interactions and cannot serve as combat captain. Dispatch state is persisted as a UTC timestamp so it survives app close/open correctly. Clock rollback is guarded by clamping elapsed time to minimum 0. The system provides `get_dispatch_state()` to Camp UI and routes item drops through the standard Equipment `award_item()` path.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| No ADR — implements GDD directly | ExplorationSystem reads Companion Data (AGI/INT/met/dispatched), writes dispatch state to SaveManager, and calls Equipment award_item() on item finds. UTC persistence via SaveManager. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-explore-001 | Dispatch stores: dispatch_start_utc, dispatch_companion_id, dispatch_duration_hours, dispatch_mission_type | New |
| TR-explore-002 | Only companions with met==true may be dispatched | New |
| TR-explore-003 | One dispatch active at a time; second dispatch attempt rejected with UI message | New |
| TR-explore-004 | Time remaining = (duration_hours * 3600) - (current_utc - start_utc), clamped to min 0 | New |
| TR-explore-005 | Clock rollback guard: time_elapsed_sec = max(0, current_utc - dispatch_start_utc) | New |
| TR-explore-006 | Gold reward: round(random_int(min,max) * duration_multiplier) | New |
| TR-explore-007 | XP reward: round(random_int(min,max) * duration_multiplier) | New |
| TR-explore-008 | Item find chance = base_find_chance + floor(agi/5), capped at MAX_FIND_CHANCE (60%) | New |
| TR-explore-009 | INT rarity shift: floor(int/10) shift points; 0=standard(65/30/5), 1=(55/35/10), 2=(45/35/20), 3+=(35/35/30) | New |
| TR-explore-010 | Dispatched companion unavailable for Talk/Gift/Date and combat captain | New |
| TR-explore-011 | XP routed to companion.xp via Companion Data path (same as combat XP) | New |
| TR-explore-012 | Item finds routed through Equipment.award_item(); full-inventory: discard with notification | New |
| TR-explore-013 | Dispatch data cleared from save after collection; no auto-collect | New |
| TR-explore-014 | invalid dispatch_duration_hours defaults to 1.0x multipliers; logs warning | New |
| TR-explore-015 | All tuning knobs in assets/data/exploration_config.json | New |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/exploration.md` are verified (AC-1 through AC-8)
- All Logic and Integration stories have passing test files in `tests/`
- All UI stories have evidence docs in `production/qa/evidence/`
- Integration with GameStore and Hub verified: dispatch state persists across simulated app close

## Next Step

Stories are defined in `production/epics/exploration/stories.md`.
