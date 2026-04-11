# Sprint 6 -- 2026-06-06 to 2026-06-20

## Sprint Goal

Complete all remaining systems — Intimacy scenes, Audio integration, Gallery polish, Achievements polish — and bring the game to Full Vision feature-complete status. Final integration testing across all 21 systems.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days
- Available: 8 days
- Sprint 5 velocity: 27 stories / 8 days
- Stories: 22

## Tasks

### Must Have — 22 stories

#### Phase A: Intimacy System (Days 1-3) — 8 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| INTIM-001 | Intimacy Scene Playback — Dialogue Integration | intimacy | Logic | 0.5 |
| INTIM-002 | CG Display + Transition System | intimacy | UI | 0.5 |
| INTIM-003 | Choice Nodes in Intimacy Scenes | intimacy | Logic | 0.25 |
| INTIM-004 | RL Award + Completion Tracking | intimacy | Logic | 0.25 |
| INTIM-005 | Gallery Unlock Notification | intimacy | Integration | 0.25 |
| INTIM-006 | Gate Check — Romance Stage Prerequisite | intimacy | Logic | 0.25 |
| INTIM-007 | Intimacy Scene UI Layout | intimacy | UI | 0.5 |
| INTIM-008 | Intimacy Integration with Camp | intimacy | Integration | 0.5 |

#### Phase B: Audio + Polish (Days 4-6) — 8 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| AUDIO-001 | Placeholder Audio Assets (26 files) | audio | Config/Data | 0.5 |
| AUDIO-002 | BGM Scene Wiring — All 16 Scenes | audio | Integration | 0.5 |
| AUDIO-003 | SFX Combat Events — Card Play, Score, Victory | audio | Integration | 0.25 |
| AUDIO-004 | SFX UI Events — Button Tap, Navigation | audio | Integration | 0.25 |
| AUDIO-005 | Tension Layer — Combat Low HP | audio | Logic | 0.25 |
| AUDIO-006 | Stinger System — Victory, Defeat, Stage Up | audio | Logic | 0.25 |
| ACHIEVE-001 | Achievements UI Polish — Progress Bars + Categories | achievements | UI | 0.5 |
| ACHIEVE-002 | Achievements Notification Popup | achievements | UI | 0.5 |

#### Phase C: Integration + End-to-End (Days 7-8) — 6 stories

| ID | Task | Epic | Type | Est. |
|----|------|------|------|------|
| INTEG-001 | Full Game Flow Test — New Game to Ch01 Complete | integration | Integration | 0.5 |
| INTEG-002 | Save/Load Round-Trip — All 21 Systems | integration | Integration | 0.5 |
| INTEG-003 | Hub Progressive Unlock — Tab Gating Logic | integration | Logic | 0.25 |
| INTEG-004 | Gallery UI Polish — Locked State, Thumbnails | gallery | UI | 0.5 |
| INTEG-005 | Settings Screen — Volume Sliders + Language | integration | UI | 0.5 |
| INTEG-006 | Final Smoke Test + Bug Sweep | integration | Integration | 0.25 |

## Carryover

None — Sprint 5 completed 27/27 stories.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Intimacy CG assets don't exist | HIGH | MEDIUM | Use placeholder colored rectangles; art pipeline separate |
| Audio files are all placeholders | HIGH | LOW | Generate silent .ogg stubs; real assets later |
| 22 stories aggressive for 8 days | MEDIUM | MEDIUM | Phase C stories can defer; intimacy + audio are priority |
| Achievements notification interrupts gameplay | LOW | MEDIUM | Queue notifications, show between scenes |

## Definition of Done

- [ ] All 22 stories completed
- [ ] Intimacy: 3 scenes per companion playable end-to-end
- [ ] Audio: BGM plays on all scenes, SFX on combat actions
- [ ] Achievements: popup notification on unlock
- [ ] Gallery: locked/unlocked CG grid functional
- [ ] Full new-game → Ch01 complete flow tested without errors
- [ ] Save/load preserves all system state
- [ ] Hub tabs unlock progressively (Story always → Camp/Deck after ch01_met_artemis → all after ch01_exposition_done)
- [ ] 641+ tests passing
- [ ] All 21 systems feature-complete
