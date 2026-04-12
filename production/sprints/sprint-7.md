# Sprint 7 -- 2026-04-12 to 2026-04-26

## Sprint Goal

Launch Prep — Polish, bug hunt, save/load integrity, balance tuning, and export configuration. Deliver a shippable Chapter 1 vertical slice ready for itch.io / Patreon build.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days
- Available: 8 days
- Stories: 18

## Tasks

### Must Have — 18 stories

#### Phase A: Save/Load + State Integrity (Days 1-2) — 5 stories

| ID | Task | Type | Est. |
|----|------|------|------|
| LAUNCH-001 | Save/load round-trip — all 21 systems | Integration | 0.5 |
| LAUNCH-002 | Continue button works mid-chapter progress | Integration | 0.25 |
| LAUNCH-003 | Save version migration stub (for future schema changes) | Logic | 0.25 |
| LAUNCH-004 | Settings persist across sessions | Integration | 0.25 |
| LAUNCH-005 | Multi-save slot support (3 slots) | Logic | 0.5 |

#### Phase B: Balance + Tuning (Days 3-4) — 5 stories

| ID | Task | Type | Est. |
|----|------|------|------|
| LAUNCH-006 | Combat difficulty curve — forest_monster → gaia_spirit | Config/Data | 0.5 |
| LAUNCH-007 | Gold economy balance — enough for 2-3 gift purchases by Ch1 end | Config/Data | 0.25 |
| LAUNCH-008 | Romance progression pacing — reach stage 2 by Ch1 end with Artemis | Config/Data | 0.5 |
| LAUNCH-009 | Token pool balance — enough for talk+gift daily | Config/Data | 0.25 |
| LAUNCH-010 | Blessing unlock timing — first blessing before mountains | Config/Data | 0.25 |

#### Phase C: Polish + Bug Hunt (Days 5-7) — 6 stories

| ID | Task | Type | Est. |
|----|------|------|------|
| LAUNCH-011 | Navigate all 16 scenes — zero errors | Integration | 0.5 |
| LAUNCH-012 | Edge case: empty save, corrupt save, missing files | Logic | 0.5 |
| LAUNCH-013 | Memory leak check — tweens, signal disconnects | Logic | 0.25 |
| LAUNCH-014 | Mobile viewport verification (430x932) on all scenes | UI | 0.5 |
| LAUNCH-015 | Back button handling — every scene returns correctly | Integration | 0.25 |
| LAUNCH-016 | Onboarding flow — first-time player can reach ch01_complete | Integration | 0.5 |

#### Phase D: Export + Ship (Day 8) — 2 stories

| ID | Task | Type | Est. |
|----|------|------|------|
| LAUNCH-017 | Export presets — Windows + Web HTML5 | Config/Data | 0.5 |
| LAUNCH-018 | README + itch.io page copy | Documentation | 0.25 |

## Definition of Done

- [ ] All 18 stories complete
- [ ] Save/load works for every system
- [ ] Chapter 1 is completable from New Game to ch01_complete without any errors
- [ ] All scenes navigate correctly with back button
- [ ] Export builds work on Windows + HTML5
- [ ] 641+ tests passing
- [ ] Ready for first external playtest

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Hidden save/load bugs | MEDIUM | HIGH | Dedicated save_load_test suite |
| Balance feels bad on real playthrough | HIGH | MEDIUM | Test in single playthrough, adjust knobs |
| Multi-save slots need schema rework | LOW | MEDIUM | Keep single-save fallback |
