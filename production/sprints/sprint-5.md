# Sprint 5 -- 2026-05-23 to 2026-06-06

## Sprint Goal

Implement 3 Alpha systems — Abyss Mode (roguelike endgame), Equipment (stat modifiers), and Exploration (dispatch missions) — extending the MVP with progression depth and replayability.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days
- Available: 8 days
- Stories: 27

## Tasks

### Must Have — 27 stories

#### Phase A: Equipment + Exploration Core (Days 1-3)

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| EQUIP-001 | Item Data Schema + JSON Loading | equipment | Logic | 0.25 |
| EQUIP-002 | Equipment Slot System (2 slots) | equipment | Logic | 0.5 |
| EQUIP-003 | Equip/Unequip + GameStore Persistence | equipment | Logic | 0.5 |
| EQUIP-004 | Scoring Pipeline Injection | equipment | Integration | 0.5 |
| EQUIP-005 | Drop Generation (rarity, boss guarantee) | equipment | Logic | 0.25 |
| EQUIP-006 | Pending Items Queue | equipment | Logic | 0.25 |
| EXPLORE-001 | Mission Data + Dispatch State | exploration | Logic | 0.25 |
| EXPLORE-002 | Real-Time Clock + UTC Persistence | exploration | Logic | 0.5 |
| EXPLORE-003 | Reward Calculation (AGI/INT) | exploration | Logic | 0.5 |
| EXPLORE-004 | Companion Availability Lock | exploration | Logic | 0.25 |
| EXPLORE-005 | Mission Complete Collection | exploration | Logic | 0.25 |

#### Phase B: Abyss Mode (Days 4-6)

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| ABYSS-001 | Ante Threshold Progression | abyss-mode | Logic | 0.25 |
| ABYSS-002 | Run State Machine | abyss-mode | Logic | 0.5 |
| ABYSS-003 | Shop System | abyss-mode | Logic | 0.5 |
| ABYSS-004 | Run-Scoped Gold | abyss-mode | Logic | 0.25 |
| ABYSS-005 | Deck Modifications During Run | abyss-mode | Logic | 0.5 |
| ABYSS-009 | CombatManager Integration | abyss-mode | Integration | 0.5 |
| ABYSS-010 | Weekly Modifier Slot | abyss-mode | Logic | 0.25 |

#### Phase C: UI + Integration (Days 7-8)

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| EQUIP-007 | Equipment UI Screen | equipment | UI | 0.5 |
| EQUIP-008 | Combat Reward Integration | equipment | Integration | 0.25 |
| EXPLORE-006 | Exploration UI | exploration | UI | 0.5 |
| EXPLORE-007 | GameStore + Hub Integration | exploration | Integration | 0.25 |
| ABYSS-006 | Between-Ante Shop UI | abyss-mode | UI | 0.5 |
| ABYSS-007 | Run Summary + Rewards | abyss-mode | Logic | 0.25 |
| ABYSS-008 | Abyss Entry from Hub | abyss-mode | Integration | 0.25 |
| ABYSS-011 | Abyss UI — Ante Display | abyss-mode | UI | 0.5 |
| ABYSS-012 | Full Abyss Run Integration | abyss-mode | Integration | 0.5 |

## Definition of Done

- [ ] All 27 stories completed
- [ ] Abyss Mode: 8-ante run completable end-to-end
- [ ] Equipment: items affect combat scoring
- [ ] Exploration: dispatch + collect cycle works with real-time clock
- [ ] All Logic/Integration stories have tests
