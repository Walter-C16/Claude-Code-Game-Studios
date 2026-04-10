# Sprint 2 -- 2026-04-25 to 2026-05-09

## Sprint Goal

Build the 4 Core layer modules — CompanionRegistry, EnemyRegistry, CombatSystem, DialogueRunner — enabling the game's primary poker combat and visual novel gameplay loops.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days
- Sprint 1 velocity: 34 stories / 8 days = 4.25 stories/day

## Tasks

### Must Have (Critical Path)

#### Phase A: Data Registries (Days 1-2) — 8 stories

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| COMPANION-001 | CompanionRegistry Static Profile Loading | companion-data | Logic | 0.5 | None | Load companions.json, get_profile(), get_all_ids(), defensive copy |
| COMPANION-002 | Element Enum + Suit Mapping | companion-data | Logic | 0.25 | COMPANION-001 | Element enum, get_element_for_suit(), unique elements per companion |
| COMPANION-003 | CompanionState — Romance Stage Derivation | companion-data | Logic | 0.5 | COMPANION-001 | get_romance_stage(), stage never decreases, EventBus signal, RL clamping |
| COMPANION-004 | Portrait Fallback System | companion-data | Logic | 0.25 | COMPANION-001 | Mood path, neutral fallback, placeholder fallback |
| COMPANION-005 | Save Migration — Missing Companions | companion-data | Integration | 0.5 | COMPANION-001, -003 | Missing companions get defaults, unknown IDs dropped |
| ENEMY-001 | EnemyRegistry Static Profile Loading | enemy-data | Logic | 0.5 | None | Load enemies.json, get_enemy(), get_enemies_by_chapter() |
| ENEMY-002 | Attack Derivation + Data Validation | enemy-data | Logic | 0.25 | ENEMY-001 | attack = floor(hp * ratio), threshold clamping, hp=0 handling |
| ENEMY-003 | Localization Key Integration | enemy-data | Integration | 0.25 | ENEMY-001 | name_key resolves via Localization, boot order verified |

#### Phase B: Poker Combat (Days 3-5) — 12 stories

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| COMBAT-001 | Deck Creation + Shuffle | poker-combat | Logic | 0.25 | COMPANION-002 | 52 cards, suit-element mapping, signature cards |
| COMBAT-002 | Hand Evaluation — 10 Ranks | poker-combat | Logic | 0.5 | COMBAT-001 | All 10 ranks with correct base chips/mult |
| COMBAT-003 | Scoring Pipeline — Chips | poker-combat | Logic | 0.5 | COMBAT-002 | Base + per-card + foil + element + captain + social, clamp(1) |
| COMBAT-004 | Scoring Pipeline — Mult + Final | poker-combat | Logic | 0.5 | COMBAT-003 | Additive mult + polychrome + captain, floor(chips * mult) |
| COMBAT-005 | Element Weakness/Resistance | poker-combat | Logic | 0.25 | COMBAT-003 | +25/+0.5 weak, -15 resist, None disables |
| COMBAT-006 | Card Enhancements | poker-combat | Logic | 0.25 | COMBAT-004 | Foil +50, Holo +10, Poly x1.5 sequential |
| COMBAT-007 | Captain Stat Bonus | poker-combat | Logic | 0.25 | COMBAT-004 | floor(STR*0.5) chips, 1.0+(INT*0.025) mult |
| COMBAT-008 | Combat State Machine | poker-combat | Logic | 0.5 | COMBAT-002 | SETUP→DRAW→SELECT→RESOLVE/DISCARD→VICTORY/DEFEAT |
| COMBAT-009 | Victory/Defeat + Social Buff | poker-combat | Logic | 0.25 | COMBAT-008 | Score vs threshold, buff consumed/retained |
| COMBAT-010 | BlessingSystem Black-Box | poker-combat | Logic | 0.25 | COMBAT-004 | Pass context, receive {chips, mult}, no inspection |
| COMBAT-011 | Combat UI Scene | poker-combat | UI | 0.5 | COMBAT-008 | Card display, selection, score animation |
| COMBAT-012 | Full Combat Integration | poker-combat | Integration | 0.5 | COMBAT-009, -011 | SceneManager, EventBus, GameStore rewards |

#### Phase C: Dialogue System (Days 6-8) — 9 stories

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| DIALOGUE-001 | JSON Script Parser + Gate | dialogue | Logic | 0.5 | None | Load JSON, prerequisite checking, blocked signal |
| DIALOGUE-002 | Typewriter Text + Tap | dialogue | Logic | 0.5 | DIALOGUE-001 | Character-by-character, skip on tap, text_speed |
| DIALOGUE-003 | Speaker Types + Portraits | dialogue | Logic | 0.25 | DIALOGUE-002, COMPANION-004 | Portrait display, mood crossfade |
| DIALOGUE-004 | Choice System — Render + Tap | dialogue | UI | 0.5 | DIALOGUE-002 | Choice buttons, tap handling |
| DIALOGUE-005 | Choice Condition Evaluation | dialogue | Logic | 0.25 | DIALOGUE-004 | Flag/stage gating at render time |
| DIALOGUE-006 | Effect System — Signals + Flags | dialogue | Logic | 0.5 | DIALOGUE-001 | relationship_changed, trust_changed via EventBus |
| DIALOGUE-007 | Sequence End + EventBus | dialogue | Integration | 0.25 | DIALOGUE-006 | dialogue_ended signal, cleanup |
| DIALOGUE-008 | Localization Integration | dialogue | Integration | 0.25 | DIALOGUE-001 | Text keys via Localization.get_text() |
| DIALOGUE-009 | Accessibility — AccessKit | dialogue | Logic | 0.25 | DIALOGUE-002 | Screen reader support |

### Should Have

None — all Core stories are critical path.

### Nice to Have

None.

## Carryover from Previous Sprint

None — Sprint 1 completed 34/34, all tests passing (464/464).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Combat scoring pipeline complexity | MEDIUM | HIGH | Prototype validated math; TDD per story |
| Dialogue JSON format undefined in code | MEDIUM | MEDIUM | ADR-0008 defines format; fixture files early |
| Data files don't exist yet | HIGH | LOW | Create in COMPANION-001 and ENEMY-001 |
| Combat UI largest single UI story | MEDIUM | MEDIUM | Prototype as reference |

## Dependencies on External Factors

- Companion portrait assets (placeholder PNGs sufficient for Sprint 2)
- No external API or service dependencies

## Definition of Done for this Sprint

- [ ] All 29 Must Have tasks completed
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] UI stories have evidence docs in `production/qa/evidence/`
- [ ] QA plan exists (`production/qa/qa-plan-sprint-2.md`)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] `project.godot` has autoloads #7-#8 (CompanionRegistry, EnemyRegistry)
- [ ] Data files: `assets/data/companions.json`, `assets/data/enemies.json`
- [ ] Code reviewed and merged
