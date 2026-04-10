# Epic: Camp + Gift Items

> **Layer**: Feature
> **GDD**: design/gdd/camp.md + design/quick-specs/gift-items.md
> **Architecture Module**: Camp (scene/UI) + GiftItems (RefCounted, static methods)
> **Governing ADRs**: ADR-0015
> **Status**: Ready
> **Stories**: Not yet created -- run `/create-stories camp`

## Overview

Camp is the Hub sub-tab where players interact with companions through Talk, Gift, and Date actions. It is a pure presentation layer -- it reads from the Romance & Social API and owns no game logic. The companion grid shows met companions in a 2-column scrollable layout. The gift picker is an in-Camp modal bottom sheet backed by GiftItems, a stateless utility that loads 6 purchasable gift items from JSON and validates gold costs. Purchase is immediate (no inventory): player selects item, gold is deducted via GameStore, and RomanceSocial processes the relationship outcome. Camp also displays token pips, streak info, mood portraits, and interaction button gating.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0015: Gift Items -- Purchase Flow + Gold Economy | Stateless RefCounted utility loading 6 gift items from JSON; validates gold, integrates with GameStore.spend_gold() and RomanceSocial.do_gift(); no inventory | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-camp-001 | Camp as Hub sub-tab using keep-alive hide/show; tab switch < 1 frame | ADR-0015 |
| TR-camp-002 | Pure presentation layer: reads from Romance & Social API; owns no game logic | ADR-0015 |
| TR-camp-003 | Companion grid: 2-column scrollable, met companions only; reactive on companion_met | ADR-0015 |
| TR-camp-004 | Gift picker as in-Camp modal overlay (60% screen height bottom sheet) | ADR-0015 |
| TR-camp-005 | Date launches full scene transition; return restores Camp tab via context payload | ADR-0015 |
| TR-camp-006 | Token pips: 3 gold pips, immediate update on spend; midnight reset via signal | ADR-0015 |
| TR-camp-007 | Gift picker 60fps open/close on 430x932 device | ADR-0015 |
| TR-camp-008 | Interaction buttons individually gated (greyed, non-tappable, not hidden) | ADR-0015 |
| TR-camp-009 | R&S API calls: get_token_count(), get_streak(), get_companion_state(id), do_talk(id), do_gift(id, item), start_date(id) | ADR-0015 |
| TR-camp-010 | No companions met state: show story-flavored prompt, no grid, no buttons | ADR-0015 |
| TR-camp-011 | Tokens exhausted: buttons disabled, 'Come back tomorrow' label replaces interaction area | ADR-0015 |
| TR-camp-012 | Grid cards >= 88x88px; gift picker items >= 44x44px touch targets | ADR-0015 |
| TR-camp-013 | Known likes/dislikes preference hint icons only rendered when romance_stage >= 2 | ADR-0015 |
| TR-camp-014 | Camp depends on Gift Items data (gift_items.json); Gift button disabled if no giftable items | ADR-0015 |

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, closed via `/story-done`
- All GDD acceptance criteria verified
- Logic/Integration stories have passing tests in `tests/`
- Visual/UI stories have evidence docs in `production/qa/evidence/`

## Next Step

Run `/create-stories camp` to break this epic into implementable stories.
