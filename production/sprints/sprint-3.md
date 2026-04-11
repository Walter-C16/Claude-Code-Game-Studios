# Sprint 3 -- 2026-05-09 to 2026-05-23

## Sprint Goal

Build all 5 Feature layer modules — RomanceSocial, StoryFlow, BlessingSystem, DeckManager, Camp — completing the full MVP gameplay loop where combat, dialogue, romance, and blessings are interconnected.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days
- Available: 8 days
- Sprint 2 velocity: 29 stories / 8 days

## Tasks

### Must Have — 37 stories

#### Phase A: Core Systems (Days 1-3) — 16 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| RS-001 | Token Pool — Daily Allocation | romance-social | Logic | 0.25 |
| RS-002 | Streak System — Multiplier Lookup | romance-social | Logic | 0.25 |
| RS-003 | Relationship Gain Formula + RL Write | romance-social | Logic | 0.5 |
| RS-004 | Mood State Machine | romance-social | Logic | 0.5 |
| RS-005 | Talk + Gift Interactions | romance-social | Logic | 0.5 |
| RS-006 | Date Sub-System — 4 Rounds | romance-social | Logic | 0.5 |
| RS-007 | Combat Buffs — Generation + Persistence | romance-social | Logic | 0.25 |
| RS-008 | romance_stage_changed + Dialogue Deltas | romance-social | Integration | 0.25 |
| RS-010 | RomanceSocial Autoload — Boot + Wiring | romance-social | Integration | 0.5 |
| DB-001 | Blessing Data — JSON Loading | divine-blessings | Logic | 0.25 |
| DB-002 | Slot Availability — Stage Gating | divine-blessings | Logic | 0.25 |
| DB-003 | Trigger Evaluation — 13 Types | divine-blessings | Logic | 0.5 |
| DB-004 | compute() — End-to-End | divine-blessings | Logic | 0.25 |
| DB-006 | BlessingSystem Integration — Pipeline Hook | divine-blessings | Integration | 0.25 |
| DM-001 | CardData Schema + Deck Builder | deck-management | Logic | 0.25 |
| DM-002 | Captain Stat Bonus Computation | deck-management | Logic | 0.25 |

#### Phase B: Flow + UI (Days 4-6) — 14 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| SF-001 | Chapter JSON — Schema + Loading | story-flow | Logic | 0.5 |
| SF-002 | Node State Machine | story-flow | Logic | 0.5 |
| SF-003 | Flag Gating + Prerequisites | story-flow | Logic | 0.25 |
| SF-004 | Reward Distribution | story-flow | Logic | 0.25 |
| SF-005 | Node Type Execution — Dialogue/Combat | story-flow | Integration | 0.5 |
| SF-006 | Mixed + Boss Node Sequences | story-flow | Logic | 0.25 |
| SF-008 | StoryFlow Autoload — Boot Wiring | story-flow | Integration | 0.25 |
| DM-003 | Captain Selection State Machine | deck-management | Logic | 0.25 |
| DM-004 | combat_configured Signal + Handoff | deck-management | Integration | 0.25 |
| CAMP-001 | GiftItems Utility — JSON + Validation | camp | Logic | 0.25 |
| CAMP-002 | Gift Purchase Flow | camp | Logic | 0.25 |
| CAMP-003 | Companion Grid Display | camp | UI | 0.5 |
| CAMP-004 | Token/Streak Display + Reset | camp | Logic | 0.25 |
| CAMP-005 | Gift Picker Modal | camp | UI | 0.5 |

#### Phase C: Polish + Integration (Days 7-8) — 7 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| RS-009 | Visual/Audio — Stage Advance Ceremony | romance-social | Visual/Feel | 0.5 |
| SF-007 | Chapter Map UI | story-flow | UI | 0.5 |
| DB-005 | Combat HUD — Blessing Icons | divine-blessings | UI | 0.25 |
| DM-005 | Deck Viewer UI | deck-management | UI | 0.5 |
| DM-006 | Captain Selection UI | deck-management | UI | 0.5 |
| CAMP-006 | Interaction Result Feedback | camp | Visual/Feel | 0.25 |
| CAMP-007 | Camp Scene Integration | camp | Integration | 0.5 |

## Carryover

None — Sprint 2 completed 29/29.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 37 stories exceeds Sprint 2 velocity of 29 | MEDIUM | MEDIUM | Phase C UI stories can defer to Sprint 4 if needed |
| BlessingSystem 13 trigger types is complex | MEDIUM | HIGH | GDD defines all triggers; implement as lookup table |
| RomanceSocial is the largest single module | HIGH | MEDIUM | Break into independent sub-stories; test each in isolation |
| StoryFlow chapter data doesn't exist yet | HIGH | LOW | Create fixture data as part of SF-001 |

## Definition of Done

- [ ] All 37 Must Have tasks completed
- [ ] All Logic/Integration stories have passing tests
- [ ] UI/Visual stories have evidence docs
- [ ] Smoke check passed
- [ ] Full MVP loop playable: Splash → Hub → Combat → Dialogue → Camp → Blessings affect combat
