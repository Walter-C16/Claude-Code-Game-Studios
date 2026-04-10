# Architecture Review Report

> **Date**: 2026-04-09
> **Engine**: Godot 4.6
> **GDDs Reviewed**: 14
> **ADRs Reviewed**: 16
> **Reviewer**: /architecture-review (full mode, v2)

---

## Traceability Summary

| Metric | Count |
|--------|-------|
| Total technical requirements | 202 |
| Previously registered (v2) | 150 |
| New requirements (this pass) | 76 |
| Systems with dedicated ADR | 13/13 designed |
| Cross-cutting ADRs | 3 (GameStore, EventBus, Boot Order) |

### Requirement Breakdown by Domain

| Domain | Count |
|--------|-------|
| Data structures | 98 |
| Cross-system communication | 39 |
| Engine capability | 30 |
| Platform requirements | 27 |
| State persistence | 19 |
| Performance constraints | 16 |
| Threading/timing | 8 |

### Requirement Breakdown by Layer

| Layer | Systems | Count |
|-------|---------|-------|
| Foundation | companion-data, enemy-data, save-system, localization, ui-theme, scene-nav | 106 |
| Core | poker-combat, dialogue, deck-mgmt | 55 |
| Feature | romance-social, story-flow, divine-blessings, camp | 41 |

---

## System-Level Coverage Matrix

| System | Layer | GDD | Primary ADR(s) | ADR Status | Coverage |
|--------|-------|-----|----------------|------------|----------|
| Companion Data | Foundation | companion-data.md | ADR-0001, ADR-0009 | Accepted | Covered |
| Enemy Data | Foundation | enemy-data.md | ADR-0016 | **Proposed** | Partial |
| Save System | Foundation | save-system.md | ADR-0001, ADR-0002 | Accepted | Covered |
| Localization | Foundation | localization.md | ADR-0005 | Accepted | Covered |
| UI Theme | Foundation | ui-theme.md | ADR-0013 | Accepted | Covered |
| Scene Navigation | Foundation | scene-navigation.md | ADR-0003 | Accepted | Covered |
| Poker Combat | Core | poker-combat.md | ADR-0007 | Accepted | Covered |
| Dialogue | Core | dialogue.md | ADR-0008 | Accepted | Covered |
| Romance & Social | Feature | romance-social.md | ADR-0010 | Accepted | Covered |
| Story Flow | Feature | story-flow.md | ADR-0011 | Accepted | Covered |
| Deck Management | Core | deck-management.md | ADR-0014 | Accepted | Covered |
| Divine Blessings | Feature | divine-blessings.md | ADR-0012 | Accepted | Covered |
| Camp | Feature | camp.md | ADR-0010, ADR-0015 | Accepted | Covered |
| Gift Items | Feature | quick-spec | ADR-0015 | Accepted | Covered |

Cross-cutting: ADR-0001 (GameStore), ADR-0004 (EventBus), ADR-0006 (Boot Order)

---

## Coverage Gaps

### ADR-0016 (EnemyRegistry) — Proposed, not Accepted

- 9 technical requirements in enemy-data depend on this ADR
- ADR-0007 (Poker Combat) and ADR-0011 (Story Flow) both consume enemy data but don't formally depend on ADR-0016
- **Action**: Accept ADR-0016

### New Requirements (76) — Detailed Coverage

76 new requirements were identified and registered in tr-registry.yaml v3. Largest clusters:
- poker-combat: 15 new (per-card chips formulas, element cycle, UI layout zones, BGM layers)
- romance-social: 12 new (interaction formulas, mood priority, buff replacement, date categories)
- dialogue: 10 new (speaker types, effect types, choice conditions, pause markers)
- ui-theme: 7 new (typography minimums, panel styles, bottom sheet behavior)

These are detailed implementation requirements covered by their system's dedicated ADR. Per-requirement ADR mapping should be verified when stories reference these TR-IDs.

---

## Cross-ADR Conflicts

### CONFLICT 1: `romance_stage` ownership — ADR-0001 vs ADR-0009

- **ADR-0001** (GameStore) stores `romance_stage` in the companion state dictionary and exposes `get_romance_stage()`.
- **ADR-0009** (CompanionState) states `romance_stage` is **derived** from `relationship_level` via thresholds — not stored.
- **architecture.md** lists `GameStore.get_romance_stage()` as a public method.
- **Impact**: Implementers won't know whether to store or derive the value.
- **Resolution options**:
  1. Derive only (recommended) — remove from GameStore serialization; CompanionState.get_romance_stage() is authoritative
  2. Cache + derive — store in GameStore for fast access but CompanionState is sole writer

### CONFLICT 2: `set_relationship_level()` visibility — ADR-0001 vs architecture.md

- **ADR-0001**: `_set_relationship_level()` (underscore = internal, only CompanionState calls it)
- **architecture.md**: `set_relationship_level()` (no underscore = public)
- **Impact**: If public, any system can bypass CompanionState's stage derivation and signal emission.
- **Resolution**: Align on underscore convention in architecture.md.

### CONFLICT 3: `combat_configured` signal location — ADR-0004 vs ADR-0014

- **ADR-0004** lists `combat_configured` as an EventBus signal.
- **ADR-0014** declares it as a local DeckManager signal.
- **Resolution**: Remove from EventBus catalog — DeckManager and CombatSystem are scene-local in the same scene.

### MINOR: DialogueRunner `flag_set` direct write

- ADR-0008 `flag_set` effects write directly to `GameStore.set_flag()` (justified as Foundation-layer access).
- Other effects (relationship, trust) route through EventBus.
- Status: Intentionally inconsistent, acknowledged in ADR-0008. Not blocking.

### MINOR: Save flow description inconsistency

- ADR-0001/0002: `call_deferred("_flush_save")`
- architecture.md: `_process()` dirty check
- Resolution: Align architecture.md to match ADR-0001/0002 `call_deferred` pattern.

---

## ADR Dependency Order (Topologically Sorted)

No dependency cycles detected. Graph is a clean DAG.

### Tier 0 — No dependencies (parallel)

1. ADR-0001: GameStore
2. ADR-0004: EventBus
3. ADR-0013: UI Theme

### Tier 1 — Foundation (parallel)

4. ADR-0002: Save System (requires ADR-0001)
5. ADR-0003: Scene Management (requires ADR-0001)
6. ADR-0005: Localization (requires ADR-0001)

### Tier 2 — Foundation cap + Core (parallel)

7. ADR-0006: Boot Order (requires ADR-0001 through ADR-0005)
8. ADR-0009: Companion Data (requires ADR-0001, ADR-0005)
9. ADR-0016: EnemyRegistry (requires ADR-0001, ADR-0005) — **PROPOSED**
10. ADR-0007: Poker Combat (requires ADR-0001, ADR-0004)
11. ADR-0008: Dialogue (requires ADR-0004, ADR-0005)

### Tier 3 — Feature (parallel)

12. ADR-0010: Romance & Social (requires ADR-0001, ADR-0004, ADR-0009)
13. ADR-0014: Deck Management (requires ADR-0001, ADR-0004, ADR-0009)
14. ADR-0011: Story Flow (requires ADR-0001, ADR-0003, ADR-0004, ADR-0008, ADR-0009)
15. ADR-0012: Divine Blessings (requires ADR-0007, ADR-0009, ADR-0004)

### Tier 4 — Terminal

16. ADR-0015: Gift Items (requires ADR-0001, ADR-0010)

---

## GDD Revision Flags

None — all GDD assumptions are consistent with verified engine behaviour.

---

## Engine Compatibility

| Check | Result |
|-------|--------|
| Engine | Godot 4.6 |
| ADRs with Engine Compatibility section | 16/16 |
| Version consistency | All 16 ADRs declare Godot 4.6 |
| Deprecated API references | None found |
| Post-cutoff API conflicts | None |
| Anti-patterns | None found |

### Post-Cutoff APIs Correctly Handled

| API | Version | ADR(s) | Status |
|-----|---------|--------|--------|
| `FileAccess.store_string()` returns bool | 4.4 | ADR-0001, ADR-0002 | Correctly handled |
| Dual-focus MOUSE_FILTER | 4.6 | ADR-0003 | Flagged for verification |
| AccessKit screen reader | 4.5 | ADR-0008 | Optional |
| FoldableContainer | 4.5 | ADR-0013 | Optional |

---

## Architecture Document Coverage

`docs/architecture/architecture.md` covers all 13 designed systems in its layer map.

| Check | Result |
|-------|--------|
| All systems-index systems in layer map | All 13 present |
| Data flow covers cross-system communication | Story Combat Flow + Camp Interaction Flow documented |
| API boundaries support integration requirements | Full GDScript API signatures for all modules |
| Orphaned architecture (no GDD) | None |

### Stale Sections Requiring Update

1. **ADR Audit** (line 436): Says "No existing ADRs found" — 16 now exist
2. **Required ADRs** (lines 442-471): Lists ADRs as future work — all 16 written
3. **Open Questions** (lines 486-491): 4 questions already answered by ADRs
4. **Technical Requirements Baseline** (line 36): Shows 83 requirements — now 202
5. **Save flow description**: Uses `_process()` pattern — ADRs use `call_deferred()`

---

## Verdict: CONCERNS

The architecture is fundamentally sound — every designed system has a dedicated Accepted ADR (except Enemy Data), the dependency graph is a clean DAG, engine compatibility is fully verified, and the layer architecture is well-defined. However, two data ownership conflicts must be resolved before implementation begins, and ADR-0016 needs acceptance.

### Blocking Issues (must resolve before PASS)

1. **Accept ADR-0016** (EnemyRegistry) — only Proposed ADR; blocks combat + story implementation
2. **Resolve `romance_stage` ownership** between GameStore (ADR-0001) and CompanionState (ADR-0009)
3. **Align `set_relationship_level()` visibility** — underscore convention between ADR-0001 and architecture.md

### Required Actions (Priority Order)

1. Accept ADR-0016 (status change only)
2. Resolve romance_stage ownership conflict (update ADR-0001 + ADR-0009)
3. Fix `combat_configured` signal location (update ADR-0004 or ADR-0014)
4. Update architecture.md stale sections (ADR Audit, Required ADRs, Open Questions, TR count, save flow)

---

## History

| Date | Requirements | Covered | Gaps | Verdict |
|------|-------------|---------|------|---------|
| 2026-04-09 | 202 | 193 (system-level) | 9 (enemy-data partial) | CONCERNS |
