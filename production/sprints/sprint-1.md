# Sprint 1 -- 2026-04-11 to 2026-04-25

## Sprint Goal

Build the complete Foundation layer — all 7 autoloads and the shared UI theme resource — so that Core and Feature layers have a stable platform to build on.

## Capacity

- Total days: 10 (2 weeks)
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)

#### Phase A: State Core (Days 1-2)

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| GS-001 | GameStore Schema + Default Initialization | game-store | Logic | 0.5 | None | 4 companion IDs with defaults, scalar fields initialized, private properties |
| GS-002 | GameStore Typed Getters/Setters | game-store | Logic | 0.5 | GS-001 | spend_gold guard, set_flag idempotent, dirty flag set on every setter |
| GS-005 | SettingsStore Autoload | game-store | Logic | 0.5 | GS-001 | Defaults (en, 1.0 volumes), to_dict/from_dict, dirty flag |
| GS-003 | Dirty-Flag + Deferred Flush | game-store | Logic | 0.5 | GS-002 | 5 setters = 1 save call, _save_pending guard, from_dict no dirty |
| GS-004 | to_dict / from_dict Serialization | game-store | Logic | 0.5 | GS-002 | Round-trip fidelity, missing key defaults, missing companion init |
| EB-001 | EventBus Signal Catalog | event-bus | Logic | 0.5 | None | ~10 typed signals, no state, no logic, extends Node |

#### Phase B: Infrastructure (Days 3-4)

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| EB-002 | EventBus Type Safety | event-bus | Logic | 0.5 | EB-001 | Typed params verified, emission/reception round-trip |
| LOC-001 | JSON String Table Loading | localization | Logic | 0.5 | None | en.json loaded in _ready, error handling for missing file |
| LOC-002 | get_text + Fallback Chain | localization | Logic | 0.5 | LOC-001 | Active locale -> English -> raw key, push_warning on fallback |
| LOC-003 | Parameter Interpolation | localization | Logic | 0.5 | LOC-002 | {{name}} syntax, missing params preserved, empty params safe |
| LOC-004 | Locale Switching + Signal | localization | Logic | 0.5 | LOC-001 | SUPPORTED_LOCALES validation, locale_changed signal, <16.6ms |
| SS-001 | SaveManager Skeleton + Constants | save-system | Config | 0.25 | GS-004 | SAVE_VERSION, SAVE_PATH, 4 public methods, boot position #5 |
| SS-002 | Atomic Save Write | save-system | Logic | 0.5 | SS-001 | Temp-file + rename, store_string bool check, <3ms |
| SS-003 | Save Load + Parse | save-system | Logic | 0.5 | SS-002 | JSON parse, corrupted file handling, has_save() |

#### Phase C: Navigation + Theme (Days 5-6)

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| SS-004 | Version Migration Chain | save-system | Logic | 0.5 | SS-003 | v0->v1 chain, current version no-op, forward compat |
| SS-005 | Delete Save + Guard | save-system | Logic | 0.25 | SS-001 | File removed, state reset, idempotent |
| SN-001 | SceneId Enum + Registry | scene-nav | Config | 0.25 | None | 16+ SceneIds, SCENE_PATHS dict, no raw .tscn outside manager |
| SN-002 | Fade Transition | scene-nav | Logic | 0.5 | SN-001 | CanvasLayer 100, 0.3s tweens, signals emit correctly |
| SN-003 | Transition State Machine | scene-nav | Logic | 0.5 | SN-002 | IDLE->FADING_OUT->LOADING->FADING_IN->IDLE, double-tap guard |
| SN-004 | Input Blocking | scene-nav | Logic | 0.5 | SN-003 | MOUSE_FILTER_STOP during transition, restored after |
| SN-005 | Arrival Context Payload | scene-nav | Logic | 0.5 | SN-003 | Read-once dict, stale context cleared, empty default |
| UT-001 | Theme .tres + Fonts | ui-theme | Config | 0.5 | None | Cinzel + Nunito Sans bundled, <16.6ms load |
| UT-002 | Color Token Palette | ui-theme | Config | 0.5 | UT-001 | 20+ tokens, WCAG AA contrast, element fg/bg variants |
| UT-003 | Typography Scale | ui-theme | Config | 0.25 | UT-001 | 12 font/size combos, no arbitrary sizes in code |
| UT-006 | Haptic Feedback | ui-theme | Logic | 0.5 | None | 3 levels (15/30/50ms), graceful degradation on Web |

#### Phase D: Integration (Days 7-8)

| ID | Task | Epic | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|------|------|------|-----------|-------------|-------------------|
| UT-004 | Panel + Button StyleBoxes | ui-theme | Config | 0.5 | UT-002 | Standard/elevated panels, 4 button states, no ripple |
| UT-005 | Touch Targets + Thumb Zone | ui-theme | UI | 0.5 | UT-004 | 44px min, 52px primary, 64px list rows, bottom 560px CTAs |
| SN-006 | Settings Overlay | scene-nav | Integration | 0.5 | SN-003 | CanvasLayer 50, underlying scene alive, close signal |
| SN-007 | Hub Tab Keep-Alive | scene-nav | Integration | 0.5 | SN-004, SN-006 | Hide/show not free, Tab 5 = overlay, Android back |
| GS-006 | Boot Order Wiring | game-store | Integration | 0.5 | GS-003, GS-004, GS-005 | project.godot order, no cross-ref in _ready |
| EB-003 | EventBus Boot + Layer Isolation | event-bus | Integration | 0.5 | EB-001, EB-002 | Boot position #3, no upward imports, cross-layer via EventBus |
| LOC-005 | Localization Boot Wiring | localization | Integration | 0.5 | LOC-004, GS-005 | Boot position #4, reads SettingsStore.locale |
| SS-006 | Continuous Persistence | save-system | Integration | 0.5 | SS-002, SS-003, GS-003 | Setter -> next frame save, 3 setters = 1 write, no combat state |
| UT-007 | UI Theme Integration | ui-theme | Integration | 0.5 | UT-002-006 | No runtime theme mutation, no default Godot controls visible |

### Should Have

None — all Foundation stories are critical path.

### Nice to Have

None.

## Carryover from Previous Sprint

N/A — this is Sprint 1.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Transition fade duration conflict (GDD 200ms vs ADR-0003 300ms) | HIGH | LOW | ADR-0003 governs code (300ms). Resolve in STORY-UT-007. |
| Godot 4.6 dual-focus touch filter | MEDIUM | MEDIUM | Test MOUSE_FILTER_STOP on mobile in SN-004 early |
| FileAccess.store_string() bool return (4.4+) | LOW | LOW | Verified in engine-reference |

## Dependencies on External Factors

- Cinzel and Nunito Sans font files must be acquired and placed in `assets/fonts/`
- No external API or service dependencies

## Definition of Done for this Sprint

- [ ] All 34 Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] `project.godot` has all 8 autoloads in correct boot order (ADR-0006)
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
